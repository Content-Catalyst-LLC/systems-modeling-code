# Infrastructure Shock Propagation Modeling Protocol

This case models shock propagation in infrastructure networks as a graph problem with dependencies, load, capacity, criticality, and cascade rules.

## Core steps

1. Define the infrastructure boundary.
2. Represent assets as nodes.
3. Represent connections, dependencies, access links, and service links as edges.
4. Assign load, capacity, criticality, and repair attributes.
5. Define initial shock scenarios.
6. Apply dependency failure rules.
7. Apply load redistribution and overload rules.
8. Track cascade diagnostics.
9. Compare scenarios.
10. Communicate uncertainty and valid use.

## Core cascade logic

A shock is not only the initiating failure. It is the path by which that failure moves through dependencies, overload, connectivity, and recovery constraints.
