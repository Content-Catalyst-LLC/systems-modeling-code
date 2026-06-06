program network_diffusion_solver
  implicit none

  integer, parameter :: n_nodes = 48
  integer, parameter :: n_steps = 30

  integer :: adjacency(n_nodes, n_nodes)
  real(8) :: state(n_nodes), next_state(n_nodes), diffusion_rate
  integer :: node_i, node_j, step
  integer :: node_degree

  adjacency = 0
  state = 0.0d0
  diffusion_rate = 0.12d0

  call add_edge(adjacency, 1, 2)
  call add_edge(adjacency, 1, 3)
  call add_edge(adjacency, 2, 4)
  call add_edge(adjacency, 3, 4)
  call add_edge(adjacency, 4, 20)
  call add_edge(adjacency, 19, 20)
  call add_edge(adjacency, 19, 35)
  call add_edge(adjacency, 35, 36)
  call add_edge(adjacency, 3, 19)
  call add_edge(adjacency, 19, 35)

  state(3) = 1.0d0
  state(19) = 0.6d0
  state(35) = 0.3d0

  print '(A)', 'step,total_state,maximum_node_state,mean_node_state'

  do step = 0, n_steps
    print '(I0,A,F12.6,A,F12.6,A,F12.6)', &
      step, ',', sum(state), ',', maxval(state), ',', sum(state) / real(n_nodes, 8)

    next_state = state

    do node_i = 1, n_nodes
      node_degree = 0

      do node_j = 1, n_nodes
        if (adjacency(node_i, node_j) == 1) node_degree = node_degree + 1
      end do

      if (node_degree > 0) then
        do node_j = 1, n_nodes
          if (adjacency(node_i, node_j) == 1) then
            next_state(node_i) = next_state(node_i) + &
              diffusion_rate * (state(node_j) - state(node_i)) / real(node_degree, 8)
          end if
        end do
      end if
    end do

    state = next_state
  end do

contains

  subroutine add_edge(adj_matrix, source_node, target_node)
    integer, intent(inout) :: adj_matrix(n_nodes, n_nodes)
    integer, intent(in) :: source_node, target_node

    adj_matrix(source_node, target_node) = 1
    adj_matrix(target_node, source_node) = 1
  end subroutine add_edge

end program network_diffusion_solver
