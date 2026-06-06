program abm_threshold_solver
  implicit none

  integer, parameter :: n_agents = 180
  integer, parameter :: n_steps = 50
  integer, parameter :: initial_adopters = 12
  integer, parameter :: neighbor_radius = 2

  logical :: adopted(n_agents)
  logical :: previous(n_agents)
  real(8) :: thresholds(n_agents)
  real(8) :: local_share
  real(8) :: adoption_rate
  real(8) :: mean_threshold
  integer :: i, time, offset, left, right
  integer :: adopted_count, local_count, new_adopters

  call random_seed()

  adopted = .false.

  do i = 1, n_agents
    call random_number(thresholds(i))
    thresholds(i) = 0.10d0 + thresholds(i) * (0.70d0 - 0.10d0)
  end do

  do i = 1, initial_adopters
    adopted(i) = .true.
  end do

  mean_threshold = sum(thresholds) / real(n_agents, 8)

  print '(A)', 'time,adoption_rate,new_adopters,mean_threshold'

  do time = 1, n_steps
    previous = adopted

    do i = 1, n_agents
      if (.not. previous(i)) then
        local_count = 0
        adopted_count = 0

        do offset = 1, neighbor_radius
          left = modulo(i - offset - 1, n_agents) + 1
          right = modulo(i + offset - 1, n_agents) + 1

          local_count = local_count + 2
          if (previous(left)) adopted_count = adopted_count + 1
          if (previous(right)) adopted_count = adopted_count + 1
        end do

        local_share = real(adopted_count, 8) / real(local_count, 8)

        if (local_share >= thresholds(i)) then
          adopted(i) = .true.
        end if
      end if
    end do

    new_adopters = 0
    do i = 1, n_agents
      if (adopted(i) .and. .not. previous(i)) new_adopters = new_adopters + 1
    end do

    adoption_rate = real(count(adopted), 8) / real(n_agents, 8)

    print '(I0,A,F12.6,A,I0,A,F12.6)', time, ',', adoption_rate, ',', new_adopters, ',', mean_threshold
  end do

end program abm_threshold_solver
