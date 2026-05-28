import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Genera y persiste un ID único por instalación de la app.
/// Se usa para verificar que la cuenta solo esté activa en 1 dispositivo.
class DeviceService {
  static const _key = 'device_install_id';
  static DeviceService? _instance;
  static DeviceService get instance => _instance ??= DeviceService._();
  DeviceService._();

  String? _cachedId;

  /// Devuelve el ID de este dispositivo, creándolo si no existe.
  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    _cachedId = id;
    return id;
  }
}
