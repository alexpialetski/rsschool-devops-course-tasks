availability_zones_config = {
  public  = 1
  private = 2
}
control_plane_config = {
  nodesNumber  = 1
  instanceType = "t3.small"
}
agent_nodes_config = {
  nodesNumber  = 2
  instanceType = "t3.micro"
}
