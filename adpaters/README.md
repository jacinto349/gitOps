#Helm deployment workflow
To deploy teh application run the following command:
```
helm install NAME PATH/ --namespace NAMESPACE [--values FILEPATH]
```
where:
- `NAME` : name of application
- `FILEPATH/` : path to the application chart.
- `NAMESPACE` : destination namespace
- `FILEPATH` : values.yaml file with configurations for the chart

## values.yaml Syntax
The values.yaml file will aggregate a group of microservices that are used for a specific service/application.`
**High-level view of file structure**
```
microservices:
 - microservice1
 - microservice2
 - microservice3
 - ...
```

Each microservice is composed of multiple resources.
List of avaiable resources:
| Syntax                  | Description                                                                                                                                                                                                                                                                                             | Version                     |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| deployment              | Resource responsible for the actual microservice.                                                                                                                                                                                                                                                       | apps/v1                     |
| service                 | An abstract way to expose an application running on a set of [Pods](https://kubernetes.io/docs/concepts/workloads/pods/) as a network service.                                                                                                                                                          | v1                          |
| horizontalpodautoscaler | Automatically updates a workload resource (such as a [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) or [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)), with the aim of automatically scaling the workload to match demand. | autoscaling/v1              |
| secret                  | A Secret is an object that contains a small amount of sensitive data such as a password, a token, or a key.                                                                                                                                                                                             | v1                          |
| serviceaccount          | A service account provides an identity for processes that run in a Pod.                                                                                                                                                                                                                                 | v1                          |
| virtualservice          | Defines a set of traffic routing rules to apply when a host is addressed.                                                                                                                                                                                                                               | networking.istio.io/v1beta1 |
| configmap               | A ConfigMap is an API object used to store non-confidential data in key-value pairs                                                                                                                                                                                                                     | v1                          |
| ingress                 | An API object that manages external access to the services in a cluster, typically HTTP.                                                                                                                                                                                                                | networking.k8s.io/v1        |
| servicemonitor          | Defines monitoring for a set of services.                                                                                                                                                                                                                                                               | monitoring.coreos.com/v1    |


##### Example
```
microservices:
  - name: service-facade-pa
    virtualservice:
      prefix: /v1/pa/Service
      route:
        - host: service-facade-pa
          portnumber: 7031
          weight: 80
    servicemonitor:
      endpoints:
      - interval: 10s
        port: http
        path: test/
      namespaceSelector:
        matchNames:
          - prod
      selector:
        matchLabels:
          app: service
    ingress:
      className: test
      tls:
        - hosts:
          - test
          secretName: test
      rules:
        - host: test
          paths:
            - path: /test
              pathType: Exact
              svcname: test
              svcport: 80
    deployment:
      minReadySeconds: 180
      progressDeadlineSeconds: 600
      replicas: 5
      revisionHistoryLimit: 10
      env:
      - name: ENVIRONMENT
        value: production
      - name: PORT
        value: "'7031'"
      - name: JAVA_MEM_ARGS
        value: -Xms512m -Xmx1250m -XX:+UseG1GC
      livenessProbe:
        httpGet:
          path: test/
          port: 80
        periodSeconds: 1
        timeoutSeconds: 10
      image: busybox
      ports:
        - containerPort: 7031
          protocol: TCP
      resources:
        limits:
          cpu: 100m
          memory: 1350Mi
        requests:
          cpu: 25m
          memory: 512Mi
      imagePullSecrets: [{ name: cbs }]
    service:
      clusterIP: 10.43.87.190
      ports:
      - name: http
        port: 7031
        protocol: TCP
        targetPort: 7031
      selector:
        app: service-facade-pa
    horizontalpodautoscaler:
      maxReplicas: 5
      minReplicas: 1
      targetCPUUtilizationPercentage: 80
    serviceaccount:
      labels:
        account: service-sa
      secrets:
      - name: service-sa-token-44859
    secret:
      data:
        ca.crt: ZGF0YQo=
        namespace: ZGF0YQo=
        token: ZGF0YQo=
      labels:
        account: payments-service-sa
      name: payments-service-sa-token-44859
    
    
```