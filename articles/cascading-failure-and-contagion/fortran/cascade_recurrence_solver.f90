program cascade_recurrence_solver
  implicit none

  integer, parameter :: node_count = 30
  integer, parameter :: max_steps = 20
  integer :: adjacency(node_count, node_count)
  integer :: degree(node_count)
  integer :: affected(node_count)
  integer :: newly_affected(node_count)
  integer :: source_node
  integer :: target_node
  integer :: step_index
  integer :: node_index
  integer :: neighbor_index
  integer :: affected_neighbors
  integer :: affected_count
  integer :: new_failures
  real(8) :: link_probability
  real(8) :: threshold
  real(8) :: exposure_share
  real(8) :: raw_value
  real(8) :: edge_value

  link_probability = 0.12d0
  threshold = 0.25d0

  adjacency = 0
  degree = 0
  affected = 0

  do source_node = 1, node_count
    do target_node = source_node + 1, node_count
      raw_value = sin(real(source_node * (target_node + 3), 8) * 12.9898d0) * 43758.5453d0
      edge_value = abs(raw_value - floor(raw_value))

      if (edge_value < link_probability) then
        adjacency(source_node, target_node) = 1
        adjacency(target_node, source_node) = 1
        degree(source_node) = degree(source_node) + 1
        degree(target_node) = degree(target_node) + 1
      end if
    end do
  end do

  affected(1) = 1
  affected(2) = 1
  affected(3) = 1

  print '(A)', 'step,affected_count,affected_share,new_failures'

  do step_index = 0, max_steps
    affected_count = sum(affected)

    if (step_index == 0) then
      new_failures = affected_count
    end if

    print '(I0,A,I0,A,F12.6,A,I0)', &
      step_index, ',', affected_count, ',', real(affected_count, 8) / real(node_count, 8), ',', new_failures

    newly_affected = 0
    new_failures = 0

    do node_index = 1, node_count
      if (affected(node_index) == 1 .or. degree(node_index) == 0) cycle

      affected_neighbors = 0

      do neighbor_index = 1, node_count
        if (adjacency(node_index, neighbor_index) == 1 .and. affected(neighbor_index) == 1) then
          affected_neighbors = affected_neighbors + 1
        end if
      end do

      exposure_share = real(affected_neighbors, 8) / real(degree(node_index), 8)

      if (exposure_share >= threshold) then
        newly_affected(node_index) = 1
        new_failures = new_failures + 1
      end if
    end do

    if (new_failures == 0) exit

    do node_index = 1, node_count
      if (newly_affected(node_index) == 1) affected(node_index) = 1
    end do
  end do

end program cascade_recurrence_solver
