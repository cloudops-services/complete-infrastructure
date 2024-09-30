[
   {
      "name": "${project}-${environment}",
      "image": "${image}",
      "cpu": ${cpu},
      "healthCheck": {
         "command": ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://0.0.0.0:${container_port}/ || exit 1"],
         "retries": 3,
         "timeout": 2,
         "interval": 5,
         "startPeriod": 60
      },
      "linuxParameters": {"initProcessEnabled": true},
      "memoryReservation": "${memory}",
      "logConfiguration": {
         "logDriver": "awslogs",
         "secretOptions": null,
         "options": {
            "awslogs-group": "${project}-${environment}",
            "awslogs-region": "${region}",
            "awslogs-create-group": "true",
            "awslogs-stream-prefix": "container-${project}"
         }
      },
      "portMappings": [
         {
            "containerPort": "${container_port}",
            "hostPort": "${container_port}"
         }
      ],
      "environment": "${environment_variables}",
      "secrets": "${secrets}",
      "readonlyRootFilesystem": true,
      "mountPoints": [
         {
            "sourceVolume": "tmp-volume",
            "containerPath": "/tmp",
            "readOnly": false
         },
         {
            "sourceVolume": "yarn-global-cache-volume",
            "containerPath": "/usr/local/share/.cache/yarn",
            "readOnly": false
         },
         {
            "sourceVolume": "yarnrc-dir-volume",
            "containerPath": "/usr/local/share/.yarnrc-dir",
            "readOnly": false
         },
         {
            "sourceVolume": "yarn-hidden-volume",
            "containerPath": "/usr/local/share/.yarn",
            "readOnly": false
         },
         {
            "sourceVolume": "ssm-var-lib",
            "containerPath": "/var/lib/amazon/ssm",
            "readOnly": false
         },
         {
            "sourceVolume": "ssm-var-log",
            "containerPath": "/var/log/amazon/ssm",
            "readOnly": false
         },
         {
            "sourceVolume": "ssm-etc",
            "containerPath": "/etc/amazon/ssm",
            "readOnly": false
         }
      ]
   }
]
