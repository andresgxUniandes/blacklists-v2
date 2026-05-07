# Creación del servicio en el cluster de ECS
aws ecs create-service \
--cluster cluster-blacklist \
--service-name servicename-blacklist \
--task-definition tsk-blacklist:1 \
--load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:636901877413:targetgroup/target-group-1/22773e004b77c858,containerName=app-ecr-blacklist-gl,containerPort=5000" \
--desired-count 1 \
--launch-type FARGATE \
--deployment-controller type=CODE_DEPLOY \
--network-configuration "awsvpcConfiguration={subnets=[subnet-0f1d30b43ce4f88d9,subnet-038866afbf4e83212],securityGroups=[sg-06ee03df40584e400],assignPublicIp=ENABLED}" \
--region us-east-1

# Creación de la aplicación en AWS CodeDeploy
aws deploy create-application \
--application-name App-Blacklist-ECS \
--compute-platform ECS \
--region us-east-1

# Creación del grupo de despliegue en AWS CodeDeploy
aws deploy create-deployment-group \
--application-name App-Blacklist-ECS \
--deployment-group-name DGP-Blacklist-ECS \
--service-role-arn arn:aws:iam::636901877413:role/ecsCodeDeployRole \
--deployment-config-name CodeDeployDefault.ECSAllAtOnce \
--deployment-style "{
\"deploymentType\": \"BLUE_GREEN\",
\"deploymentOption\": \"WITH_TRAFFIC_CONTROL\"
}" \
--ecs-services "clusterName=cluster-blacklist,serviceName=servicename-blacklist" \
--load-balancer-info "{
\"targetGroupPairInfoList\": [
{
\"targetGroups\": [
{\"name\": \"target-group-1\"},
{\"name\": \"target-group-2\"}
],
\"prodTrafficRoute\": {
\"listenerArns\": [\"arn:aws:elasticloadbalancing:us-east-1:636901877413:listener/app/lb-blacklist/3f8a07c726dc9f23/f1559fe5aa9b9583\"]
}
}
]
}" \
--blue-green-deployment-configuration "{
\"terminateBlueInstancesOnDeploymentSuccess\": {
\"action\": \"TERMINATE\",
\"terminationWaitTimeInMinutes\": 5
},
\"deploymentReadyOption\": {
\"actionOnTimeout\": \"CONTINUE_DEPLOYMENT\"
}
}" \
--region us-east-1

# Ver los eventos de los logs del servicio en CloudWatch Logs
aws logs get-log-events \
    --log-group-name /ecs/tsk-blacklist \
    --log-stream-name "ecs/app-ecr-blacklist-gl/d60dca5616f74c86a0760f6bce9a25c3" \
    --region us-east-1 \
    --query 'events[*].message' \
    --output text