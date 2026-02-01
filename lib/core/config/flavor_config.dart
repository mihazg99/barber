import 'app_environment.dart';
import 'flavor_values.dart';

class FlavorConfig {
  final AppEnvironment environment;
  final FlavorValues values;

  static late final FlavorConfig _instance;

  factory FlavorConfig({
    required AppEnvironment environment,
    required FlavorValues values,
  }) {
    _instance = FlavorConfig._internal(environment, values);
    return _instance;
  }

  FlavorConfig._internal(this.environment, this.values);

  static FlavorConfig get instance => _instance;

  static bool isDev() => _instance.environment == AppEnvironment.dev;
  static bool isStaging() => _instance.environment == AppEnvironment.staging;
  static bool isProd() => _instance.environment == AppEnvironment.prod;
}