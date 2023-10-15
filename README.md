# hello-ecs-app-mesh

Demo app showing ECS AppMesh:

- Counter
  - ECS Service and Mesh Virtual Node/Service
  - simple java webapp which connects to Redis (via mesh / service discovery) and
    outputs a "hello (count is 1234)" type response
- Redis
  - ECS Service and Mesh Virtual Node/Service
  - just serves as a central counter
- Virtual-Gateway
    - ECS Service with NLB and Virtual Gateway
    - Serves as entry point to mesh

## Notes

- ECS Console does NOT support App mesh except in Classic version
  - legacy ECS Console EOL Dec 2023
  - App Mesh obsolete in favor of Service Connect?

## TODO

- add Router
    - maybe route to 2 different redis with weighting
- access logging feature
