program stock_flow_translation_solver
  implicit none

  integer :: period
  real(8) :: demand, capacity, backlog, trust, rework, learning
  real(8) :: service_gap, service_quality, conceptual_score, modeled_score
  real(8) :: pressure_gain, redesign_gain, delayed_learning_effect
  real(8) :: demand_growth, capacity_growth, rework_rate
  real(8) :: trust_loss_from_backlog, trust_gain_from_service
  real(8) :: intervention_pressure, systems_redesign_strength
  real(8) :: delay_factor, uncertainty_humility

  demand = 80.0d0
  capacity = 70.0d0
  backlog = 22.0d0
  trust = 58.0d0
  rework = 8.0d0
  learning = 22.0d0

  demand_growth = 0.018d0
  capacity_growth = 0.014d0
  rework_rate = 0.012d0
  trust_loss_from_backlog = 0.005d0
  trust_gain_from_service = 0.008d0
  intervention_pressure = 0.28d0
  systems_redesign_strength = 0.78d0
  delay_factor = 0.25d0
  uncertainty_humility = 0.82d0

  print '(A)', 'period,demand,capacity,backlog,trust,rework,learning,service_quality,conceptual_score,modeled_score,conceptual_model_gap'

  do period = 0, 80
    service_gap = max(demand + backlog - capacity, 0.0d0)
    service_quality = min(100.0d0, max(0.0d0, 100.0d0 - service_gap * 0.50d0 - rework * 0.35d0))

    conceptual_score = min(100.0d0, max(0.0d0, &
      50.0d0 + systems_redesign_strength * 24.0d0 + uncertainty_humility * 14.0d0 - &
      intervention_pressure * 8.0d0 - service_gap * 0.08d0))

    modeled_score = min(100.0d0, max(0.0d0, &
      service_quality * 0.30d0 + trust * 0.25d0 + learning * 0.20d0 + capacity * 0.10d0 - &
      backlog * 0.10d0 - rework * 0.15d0))

    print '(I0,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6)', &
      period, ',', demand, ',', capacity, ',', backlog, ',', trust, ',', rework, ',', learning, ',', service_quality, ',', &
      conceptual_score, ',', modeled_score, ',', conceptual_score - modeled_score

    pressure_gain = intervention_pressure * 4.0d0
    redesign_gain = systems_redesign_strength * 3.2d0
    delayed_learning_effect = learning * 0.03d0 * (1.0d0 - delay_factor)

    demand = demand + demand_growth * demand
    capacity = capacity + capacity_growth * capacity + redesign_gain + delayed_learning_effect - rework * 0.015d0
    backlog = backlog + demand * 0.10d0 + rework * 0.30d0 - capacity * 0.09d0 - redesign_gain * 0.80d0
    rework = rework + service_gap * rework_rate + pressure_gain * 0.15d0 - redesign_gain * 0.45d0
    trust = trust - backlog * trust_loss_from_backlog + service_quality * trust_gain_from_service + redesign_gain * 0.10d0
    learning = learning + uncertainty_humility * 1.3d0 + systems_redesign_strength * 1.1d0 - intervention_pressure * 0.45d0

    demand = min(200.0d0, max(0.0d0, demand))
    capacity = min(200.0d0, max(0.0d0, capacity))
    backlog = min(200.0d0, max(0.0d0, backlog))
    trust = min(100.0d0, max(0.0d0, trust))
    rework = min(120.0d0, max(0.0d0, rework))
    learning = min(100.0d0, max(0.0d0, learning))
  end do

end program stock_flow_translation_solver
