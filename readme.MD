## Creating the reusable module for backend and frontend components
1.creating target group (creating the target group for frontend and backend components)
for frontend the port is 80 and backend port is 8080
2.creating the instances (Creating the instances for frontend and backend components)
3.configure the application in the instances using terraform_data
4.stopping the instance 
5.Taking the AMI ID from the instance
6.terminate the instances 
7.create the launch template (after taking the Image AMI then launching the template using launch template)
8.taking the launch template and attaching it to autoscaling group(based on launch template AMI creating the autoscaling group)
9.taking the autoscaling group and attaching it to autoscaling policy(based on the cpu/memory utilization)




--> Load balancer will check instances health inside target group if the instances are unhealthy then load balancer will send response to target groups
--> then target groups will be attach instances to that autoscaling group and if instances is unhealthy then it will automatically scale up and if there is less traffic then instances will scale down 
--> here adding autoscaling policy which gives cpu/memory/disk usage and set some condition based on that it will send request to autoscaling group bcoz autoscaling policy is dependent on autoscaling group if the autoscaling policy exceeds then it will increase that
--> First stopping the instance, taking the AMI ID(which contains our configured application in that instances),terminate the instance after taking AMI ID, creating launch template with that AMI ID, Creating autoscaling group and attach autoscaling policy to that
