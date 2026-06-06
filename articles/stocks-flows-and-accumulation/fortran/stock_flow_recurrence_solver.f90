program stock_flow_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 120
  integer :: time_index
  real(8) :: backlog
  real(8) :: resource
  real(8) :: condition_value
  real(8) :: arrivals
  real(8) :: completions
  real(8) :: backlog_net
  real(8) :: regeneration
  real(8) :: extraction
  real(8) :: resource_net
  real(8) :: maintenance
  real(8) :: wear
  real(8) :: condition_net

  backlog = 80.0d0
  resource = 600.0d0
  condition_value = 72.0d0

  print '(A)', 'time,backlog,resource,infrastructure_condition,backlog_net_flow,resource_net_flow,condition_net_flow'

  do time_index = 1, n_steps
    if (time_index < 70) then
      arrivals = 18.0d0
      extraction = 24.0d0
      maintenance = 0.9d0
    else
      arrivals = 13.0d0
      extraction = 12.0d0
      maintenance = 2.8d0
    end if

    completions = min(backlog + arrivals, 12.0d0 + 0.08d0 * backlog)
    backlog_net = arrivals - completions
    backlog = max(0.0d0, backlog + backlog_net)

    regeneration = 0.045d0 * resource * (1.0d0 - resource / 1000.0d0)
    resource_net = regeneration - extraction
    resource = max(0.0d0, resource + resource_net)

    wear = 1.4d0 + 0.012d0 * max(0.0d0, 100.0d0 - condition_value)
    condition_net = maintenance - wear
    condition_value = min(100.0d0, max(0.0d0, condition_value + condition_net))

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', backlog, ',', resource, ',', condition_value, ',', backlog_net, ',', resource_net, ',', condition_net
  end do

end program stock_flow_recurrence_solver
