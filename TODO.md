- try updating mesh to block external access - and get counter->redis communication to work
    - metrics on whether mesh is actually uses vs CloudMap DNS?
    - use YELB bloc example?
- Consider swapping Nat GW for AppMesh PrivateLink Endpoint
    - or just use Fargate only with public IPs?
- docker health check needs longer timeout than 2s?

- Envoy sidecar failing health check -- NAT GW

```
              sh-4.2$ curl -s http://localhost:9901/server_info | grep state
 "state": "PRE_INITIALIZING",
```

```
 [2023-09-24 18:28:00.167][21][warning][config] [./source/common/config/grpc_stream.h:153] StreamAggregatedResources gRPC config stream to appmesh-envoy-management.us-east-1.amazonaws.com:443 closed: 13,
```

- set up envoy sidecars
    - auto-inject capability?
    - update counter app to rely on AppMesh name rather than direct to DNS (from Service Discovery)


curl -v -k -H 'Content-Type: application/grpc' -X POST https://appmesh-envoy-management.eu-west-1.amazonaws.com:443/envoy.service.discovery.v3.AggregatedDiscoveryService/StreamAggregatedResources