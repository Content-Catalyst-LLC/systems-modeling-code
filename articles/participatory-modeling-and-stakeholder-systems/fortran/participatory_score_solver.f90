program participatory_score_solver
  implicit none

  integer, parameter :: stakeholder_count = 6
  integer, parameter :: scenario_count = 5
  integer :: i, j

  character(len=40) :: stakeholder_names(stakeholder_count)
  character(len=40) :: scenario_names(scenario_count)
  real(8) :: stakeholder_weights(stakeholder_count, 5)
  real(8) :: scenario_values(scenario_count, 5)
  real(8) :: score

  stakeholder_names = (/ &
    'community_residents                  ', &
    'frontline_staff                      ', &
    'technical_experts                    ', &
    'public_agency                        ', &
    'service_users                        ', &
    'resource_managers                    ' /)

  scenario_names = (/ &
    'targeted_service_expansion           ', &
    'infrastructure_repair_priority       ', &
    'digital_monitoring_platform          ', &
    'community_led_resilience             ', &
    'baseline_policy_continuation         ' /)

  stakeholder_weights = reshape((/ &
    0.30d0,0.10d0,0.20d0,0.30d0,0.10d0, &
    0.20d0,0.15d0,0.25d0,0.20d0,0.20d0, &
    0.15d0,0.20d0,0.30d0,0.15d0,0.20d0, &
    0.20d0,0.25d0,0.25d0,0.15d0,0.15d0, &
    0.35d0,0.10d0,0.15d0,0.30d0,0.10d0, &
    0.15d0,0.20d0,0.30d0,0.15d0,0.20d0 /), (/ stakeholder_count, 5 /))

  scenario_values = reshape((/ &
    0.85d0,0.55d0,0.65d0,0.90d0,0.60d0, &
    0.55d0,0.65d0,0.85d0,0.50d0,0.75d0, &
    0.60d0,0.50d0,0.70d0,0.45d0,0.70d0, &
    0.75d0,0.70d0,0.80d0,0.85d0,0.55d0, &
    0.40d0,0.90d0,0.35d0,0.30d0,0.85d0 /), (/ scenario_count, 5 /))

  print '(A)', 'stakeholder_group,scenario,score'

  do i = 1, stakeholder_count
    do j = 1, scenario_count
      score = stakeholder_weights(i,1) * scenario_values(j,1) + &
              stakeholder_weights(i,2) * scenario_values(j,2) + &
              stakeholder_weights(i,3) * scenario_values(j,3) + &
              stakeholder_weights(i,4) * scenario_values(j,4) + &
              stakeholder_weights(i,5) * scenario_values(j,5)

      print '(A,A,A,A,F12.6)', trim(stakeholder_names(i)), ',', trim(scenario_names(j)), ',', score
    end do
  end do

end program participatory_score_solver
