library;

// Core exports
export 'core/constants/app_constants.dart';
export 'core/errors/exceptions.dart';
export 'core/utils/parallel_processor.dart';

// Domain exports
export 'features/proxy_management/domain/entities/proxy.dart';
export 'features/proxy_management/domain/entities/proxy_score.dart';
export 'features/proxy_management/domain/repositories/proxy_repository.dart';
export 'features/proxy_management/domain/usecases/get_proxies.dart';
export 'features/proxy_management/domain/usecases/validate_proxy.dart';
export 'features/proxy_management/domain/usecases/get_validated_proxies.dart';

// Data exports
export 'features/proxy_management/data/models/proxy_model.dart';
export 'features/proxy_management/data/datasources/proxy_remote_datasource.dart';
export 'features/proxy_management/data/datasources/proxy_local_datasource.dart';
export 'features/proxy_management/data/repositories/proxy_repository_impl.dart';

// Presentation exports
export 'features/proxy_management/presentation/managers/proxy_manager.dart';

// HTTP integration exports
export 'features/http_integration/http/http_proxy_client.dart';
export 'features/http_integration/dio/dio_proxy_interceptor.dart';
