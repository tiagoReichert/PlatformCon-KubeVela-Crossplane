"three-tier-app": {
	alias: ""
	annotations: {}
	attributes: workload: definition: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
	}
	description: ""
	labels: {}
	type: "component"
}

template: {
	output: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			labels: context.name + "-frontend"
			name: context.name + "-frontend"
			namespace: context.namespace
		}
		spec: {
			selector: matchLabels: "app.oam.dev/component": context.name + "-frontend"
			template: {
				metadata: labels: "app.oam.dev/component": context.name + "-frontend"
				spec: containers: [{
					image: parameter.frontend_image
					name:  context.name + "-frontend"
				}]
			}
		}
	}
	outputs: {
		"backend": {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				labels: context.name + "-backend"
				name: context.name + "-backend"
				namespace: context.namespace
			}
			spec: {
				selector: matchLabels: "app.oam.dev/component": context.name + "-backend"
				template: {
					metadata: labels: "app.oam.dev/component": context.name + "-backend"
					spec: {
					  containers: [{
						image: parameter.backend_image
						name:  context.name + "-backend"
					  }]
					  serviceAccountName: context.name + "-sa"
					}
				}
			}
		}
		"backend-service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				labels: context.name + "-backend-svc"
				name: context.name + "-backend-svc"
				namespace: context.namespace
			}
			spec: {
				selector: "app.oam.dev/component": context.name + "-backend"
				ports: [{
					name:       "http-port"
					port:       8080
					protocol:   "TCP"
					targetPort: 8080
				}]
			}
		}
		"frontend-service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				labels: context.name + "-frontend-svc"
				name: context.name + "-frontend-svc"
				namespace: context.namespace
			}
			spec: {
				selector: "app.oam.dev/component": context.name + "-frontend"
				ports: [{
					name:       "http-port"
					port:       80
					protocol:   "TCP"
					targetPort: 80
				}]
			}
		}
		"ingress": {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				namespace: context.namespace
				labels: context.name + "-ingress"
				annotations: {
					"alb.ingress.kubernetes.io/group.name":       context.name
					"alb.ingress.kubernetes.io/healthcheck-path": "/"
					"alb.ingress.kubernetes.io/scheme":           "internet-facing"
					"alb.ingress.kubernetes.io/target-type":      "ip"
				}
				name: context.name + "-ingress"
			}
			spec: {
				ingressClassName: "alb"
				rules: [{
					http: paths: [{
						backend: service: {
							name: context.name + "-backend-svc"
							port: number: parameter.backend_port
						}
						path:     "/api"
						pathType: "Prefix"
					}, {
						backend: service: {
							name: context.name + "-frontend-svc"
							port: number: parameter.frontend_port
						}
						path:     "/"
						pathType: "Prefix"
					}]
				}]
			}
		}
	}

	parameter: {
		frontend_image: string
		frontend_port: int
		backend_image: string
		backend_port: int
	}
}
