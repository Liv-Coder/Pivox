library;

// Core domain models and interfaces
export 'src/pivox_client.dart';
export 'src/domain/models/proxy.dart';
export 'src/domain/proxy_pool_manager.dart';
export 'src/domain/proxy_validator.dart';
export 'src/domain/proxy_rotation_strategy.dart';
export 'src/domain/proxy_source.dart';

// Infrastructure implementations
export 'src/infrastructure/pool/default_proxy_pool_manager.dart';
export 'src/infrastructure/rotation/round_robin_rotation.dart';

// Proxy sources
export 'src/infrastructure/sources/free_proxy_list_scraper.dart';
export 'src/infrastructure/sources/proxy_api_source.dart';
export 'src/infrastructure/sources/geonode_proxy_source.dart';
export 'src/infrastructure/sources/proxy_scrape_source.dart';
export 'src/infrastructure/sources/proxy_nova_source.dart';

// Validators and HTTP clients
export 'src/infrastructure/validation/http_proxy_validator.dart';
export 'src/infrastructure/validation/socks_proxy_validator.dart';
export 'src/infrastructure/http/pivox_http_client.dart';
