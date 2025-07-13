availability_zones_count=2
control_plane_config = {
  nodesNumber  = 1
  instanceType = "t3.medium"
}
agent_nodes_config = {
  nodesNumber  = 2
  instanceType = "t3.micro"
}