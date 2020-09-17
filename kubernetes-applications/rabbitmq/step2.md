Create a namespace for the installation target.

`kubectl create namespace rabbit`{{execute}}

Add the chart repository for the Helm chart to be installed.

`helm repo add stable https://kubernetes-charts.storage.googleapis.com`{{execute}}

Provisioning RabbitMQ on Kubernetes is easy, just install this [Helm chart](https://github.com/helm/charts/tree/master/stable/rabbitmq).

Add the repo where the chart is hosted.

`helm repo add bitnami https://charts.bitnami.com/bitnami`{{execute}}

Install the chart.

`helm install my-rabbit bitnami/rabbitmq --version 7.5.6 --namespace rabbit -f rabbit-values.yaml`{{execute}}

The RabbitMQ containers take a few moments to start. To get a status of provisioning this sequence, run this inspection.

`watch kubectl get services,statefulsets,pods --namespace rabbit`{{execute}}

In a few moments the 3 StatefulSet Pods (RabbitMQ _Nodes_) labeled `pod/my-rabbit-rabbitmq-ha-[0|1|2]` will appear and move to the _Running_ status. Once all are running, discontinue the watch. Use this `clear`{{execute interrupt}} to break out of the watch or press <kbd>Ctrl</kbd>+<kbd>C</kbd>.
