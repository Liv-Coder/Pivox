library;

// Core exports
export 'core/constants/app_constants.dart';
export 'core/errors/exceptions.dart';
export 'core/utils/parallel_processor.dart';
export 'core/builders/pivox_builder.dart';

// Domain exports
export 'features/proxy_management/domain/entities/proxy.dart';
export 'features/proxy_management/domain/entities/proxy_auth.dart';
export 'features/proxy_management/domain/entities/proxy_filter_options.dart';
export 'features/proxy_management/domain/entities/proxy_protocol.dart';
export 'features/proxy_management/domain/entities/proxy_score.dart';
export 'features/proxy_management/domain/entities/proxy_validation_options.dart';
export 'features/proxy_management/domain/repositories/proxy_repository.dart';
export 'features/proxy_management/domain/services/proxy_analytics_service.dart';
export 'features/proxy_management/domain/services/proxy_preloader_service.dart';
export 'features/proxy_management/domain/strategies/proxy_rotation_strategy.dart'
    hide RotationStrategyType;
export 'features/proxy_management/domain/strategies/rotation_strategy_factory.dart';
export 'features/proxy_management/domain/strategies/advanced_rotation_strategy.dart';
export 'features/proxy_management/domain/strategies/geo_rotation_strategy.dart';
export 'features/proxy_management/domain/strategies/weighted_rotation_strategy.dart';
export 'features/proxy_management/domain/usecases/get_proxies.dart';
export 'features/proxy_management/domain/usecases/validate_proxy.dart';
export 'features/proxy_management/domain/usecases/get_validated_proxies.dart';

// Data exports
export 'features/proxy_management/data/models/proxy_model.dart';
export 'features/proxy_management/data/datasources/proxy_remote_datasource.dart';
export 'features/proxy_management/data/datasources/proxy_local_datasource.dart';
export 'features/proxy_management/data/repositories/proxy_repository_impl.dart';
export 'features/proxy_management/data/repositories/socks_proxy_validator.dart';
export 'features/proxy_management/data/cache/proxy_cache_manager.dart';

// Presentation exports
export 'features/proxy_management/presentation/managers/proxy_manager.dart';
export 'features/proxy_management/presentation/managers/advanced_proxy_manager.dart';
export 'features/proxy_management/presentation/managers/advanced_proxy_manager_adapter.dart';

// HTTP integration exports
export 'features/http_integration/http/http_proxy_client.dart';
export 'features/http_integration/dio/dio_proxy_interceptor.dart';
