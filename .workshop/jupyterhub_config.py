c.KubeSpawner.privileged = True

resource_budget_mapping['custom'] = {
    "resource-limits" : {
        "kind": "LimitRange",
        "apiVersion": "v1",
        "metadata": {
            "name": "resource-limits",
            "annotations": {
                "resource-budget": "custom"
            }
        },
        "spec": {
            "limits": [
                {
                    "type": "Pod",
                    "max": {
                        "cpu": "8",
                        "memory": "8Gi"
                    }
                },
                {
                    "type": "Container",
                    "max": {
                        "cpu": "8",
                        "memory": "8Gi"
                    },
                    "default": {
                        "cpu": "250m",
                        "memory": "256Mi"
                    },
                    "defaultRequest": {
                        "cpu": "50m",
                        "memory": "128Mi"
                    }
                },
                {
                    "type": "PersistentVolumeClaim",
                    "min": {
                        "storage": "1Gi"
                    },
                    "max": {
                        "storage": "20Gi"
                    }
                }
            ]
        }
    },
    "compute-resources" : {
        "kind": "ResourceQuota",
        "apiVersion": "v1",
        "metadata": {
            "name": "compute-resources",
            "annotations": {
                "resource-budget": "custom"
            }
        },
        "spec": {
            "hard": {
                "limits.cpu": "8",
                "limits.memory": "8Gi"
            },
            "scopes": [
                "NotTerminating"
            ]
        }
    },
    "compute-resources-timebound" : {
        "kind": "ResourceQuota",
        "apiVersion": "v1",
        "metadata": {
            "name": "compute-resources-timebound",
            "annotations": {
                "resource-budget": "custom"
            }
        },
        "spec": {
            "hard": {
                "limits.cpu": "8",
                "limits.memory": "8Gi"
            },
            "scopes": [
                "Terminating"
            ]
        }
    },
    "object-counts" : {
        "kind": "ResourceQuota",
        "apiVersion": "v1",
        "metadata": {
            "name": "object-counts",
            "annotations": {
                "resource-budget": "custom"
            }
        },
        "spec": {
            "hard": {
                "persistentvolumeclaims": "18",
                "replicationcontrollers": "35",
                "secrets": "45",
                "services": "30"
            }
        }
    }
}
