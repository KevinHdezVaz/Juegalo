import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PAYPAL_BASE = Deno.env.get('PAYPAL_MODE') === 'live'
  ? 'https://api-m.paypal.com'
  : 'https://api-m.sandbox.paypal.com'

// ── Obtener token de acceso PayPal ────────────────────────────────
async function getPayPalToken(): Promise<string> {
  const clientId     = Deno.env.get('PAYPAL_CLIENT_ID')!
  const clientSecret = Deno.env.get('PAYPAL_CLIENT_SECRET')!
  const credentials  = btoa(`${clientId}:${clientSecret}`)

  const res = await fetch(`${PAYPAL_BASE}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${credentials}`,
      'Content-Type':  'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`PayPal auth failed: ${err}`)
  }

  const data = await res.json()
  return data.access_token
}

// ── Enviar pago por PayPal Payouts ────────────────────────────────
async function sendPayout(token: string, requestId: string, email: string, amount: number): Promise<string> {
  const res = await fetch(`${PAYPAL_BASE}/v1/payments/payouts`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type':  'application/json',
    },
    body: JSON.stringify({
      sender_batch_header: {
        sender_batch_id: requestId,
        email_subject:   '¡Recibiste un pago de Juegalo!',
        email_message:   'Felicidades, tu retiro de Juegalo ha sido procesado.',
      },
      items: [{
        recipient_type: 'EMAIL',
        amount: {
          value:    amount.toFixed(2),
          currency: 'USD',
        },
        receiver:   email,
        note:       'Retiro de monedas Juegalo',
        sender_item_id: requestId,
      }],
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`PayPal payout failed: ${err}`)
  }

  const data = await res.json()
  return data.batch_header?.payout_batch_id ?? 'unknown'
}

// ── Obtener access token OAuth2 para FCM v1 ───────────────────────
async function getFcmAccessToken(): Promise<string> {
  const serviceAccountJson = Deno.env.get('FCM_SERVICE_ACCOUNT')
  if (!serviceAccountJson) throw new Error('FCM_SERVICE_ACCOUNT no configurada')

  const sa = JSON.parse(serviceAccountJson)

  // Construir JWT para el intercambio de token
  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  // Encodear header y payload en base64url
  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const header  = encode({ alg: 'RS256', typ: 'JWT' })
  const body    = encode(payload)
  const signing = `${header}.${body}`

  // Importar clave privada RSA
  const pemKey = sa.private_key as string
  const pemContent = pemKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  const keyData = Uint8Array.from(atob(pemContent), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8', keyData.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign']
  )

  // Firmar
  const sigBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signing)
  )
  const signature = btoa(String.fromCharCode(...new Uint8Array(sigBuffer)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const jwt = `${signing}.${signature}`

  // Intercambiar JWT por access token
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  if (!tokenRes.ok) throw new Error(`OAuth2 falló: ${await tokenRes.text()}`)
  const tokenData = await tokenRes.json()
  return tokenData.access_token
}

// ── Enviar push notification vía FCM v1 ──────────────────────────
async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  const projectId = Deno.env.get('FCM_PROJECT_ID')
  if (!projectId) {
    console.warn('⚠️ FCM_PROJECT_ID no configurado, omitiendo notificación')
    return
  }

  let accessToken: string
  try {
    accessToken = await getFcmAccessToken()
  } catch (e) {
    console.warn(`⚠️ No se pudo obtener token FCM: ${e}`)
    return
  }

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type':  'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data: data ?? {},
          android: { priority: 'high' },
          apns: {
            payload: { aps: { sound: 'default' } },
          },
        },
      }),
    }
  )

  if (!res.ok) {
    console.warn(`⚠️ FCM v1 falló: ${await res.text()}`)
  } else {
    console.log('🔔 Push enviada correctamente (FCM v1)')
  }
}

// ── Handler principal ─────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Obtener requests pendientes de PayPal
  const { data: pendingRequests, error: fetchError } = await supabase
    .from('cashout_requests')
    .select('id, user_id, amount_usd, account')
    .eq('status', 'pending')
    .eq('method', 'paypal')
    .order('created_at', { ascending: true })
    .limit(50)

  if (fetchError) {
    return new Response(JSON.stringify({ error: fetchError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  if (!pendingRequests || pendingRequests.length === 0) {
    return new Response(JSON.stringify({ message: 'No hay pagos pendientes', processed: 0 }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  console.log(`Procesando ${pendingRequests.length} pagos pendientes...`)

  // Obtener token PayPal una sola vez
  let paypalToken: string
  try {
    paypalToken = await getPayPalToken()
  } catch (e) {
    return new Response(JSON.stringify({ error: `PayPal auth: ${e}` }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const results = []

  for (const req of pendingRequests) {
    try {
      // Marcar como "processing" antes de enviar
      await supabase
        .from('cashout_requests')
        .update({ status: 'processing' })
        .eq('id', req.id)

      const batchId = await sendPayout(paypalToken, req.id, req.account, req.amount_usd)

      // Marcar como "paid"
      await supabase
        .from('cashout_requests')
        .update({
          status:       'paid',
          notes:        `PayPal batch_id: ${batchId}`,
          processed_at: new Date().toISOString(),
        })
        .eq('id', req.id)

      console.log(`✅ Pagado: ${req.id} → ${req.account} → $${req.amount_usd}`)
      results.push({ id: req.id, status: 'paid', batch_id: batchId })

      // ── Enviar push notification al usuario ──────────────────
      try {
        const { data: userData } = await supabase
          .from('users')
          .select('fcm_token')
          .eq('id', req.user_id)
          .single()

        if (userData?.fcm_token) {
          await sendPushNotification(
            userData.fcm_token,
            '🎉 ¡Tu pago llegó!',
            `Recibiste $${Number(req.amount_usd).toFixed(2)} USD en tu PayPal. ¡Sigue ganando!`,
            { screen: 'wallet', type: 'cashout_paid' }
          )
        }
      } catch (notifErr) {
        // No fallar el pago si la notificación falla
        console.warn(`⚠️ Notificación falló para ${req.user_id}: ${notifErr}`)
      }

    } catch (e) {
      // Revertir a "pending" para que el admin pueda procesarlo manualmente
      await supabase
        .from('cashout_requests')
        .update({
          status: 'pending',
          notes:  `Auto-pay falló (${e instanceof Error ? e.message : String(e)}). Pendiente de pago manual.`,
        })
        .eq('id', req.id)

      console.error(`⚠️ Auto-pay falló en ${req.id}, revertido a pending: ${e}`)
      results.push({ id: req.id, status: 'reverted_to_pending', error: String(e) })
    }
  }

  return new Response(JSON.stringify({ processed: results.length, results }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
