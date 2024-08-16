from diagrams import Cluster, Diagram
from diagrams.aws.compute import Lambda
from diagrams.aws.database import ElastiCache, RDS
from diagrams.aws.network import ELB, Route53, APIGateway
from diagrams.aws.management  import Cloudwatch

with Diagram("Clustered Web Services with Logs", show=False):
    dns = Route53("dns")
    lb = ELB("lb")
    api_gateway = APIGateway("API Gateway")

    with Cluster("Services"):
        lambda_group = [Lambda("web1"),
                        Lambda("web2"),
                        Lambda("web3")]

    with Cluster("DB Cluster"):
        db_primary = RDS("userdb")
        db_primary - [RDS("userdb ro")]

    memcached = ElastiCache("memcached")
    logs = Cloudwatch("logs")

    dns >> lb >> api_gateway >> lambda_group
    lambda_group >> db_primary
    lambda_group >> memcached
    lambda_group >> logs
    api_gateway >> logs