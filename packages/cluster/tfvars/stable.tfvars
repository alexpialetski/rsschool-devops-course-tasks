availability_zones_count = {
  public  = 1
  private = 1
}
control_plane_config = {
  nodesNumber  = 1
  instanceType = "t3.small"
}
agent_nodes_config = {
  nodesNumber  = 1
  instanceType = "t3.micro"
}
