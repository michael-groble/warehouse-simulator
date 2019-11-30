# WarehouseSimulator

Simulates picking orders on a sequential line in a warehouse.  Not a huge amount of functionality here,
mainly a learning opportunity to explore Elixir.

Two files define the inputs to the simulation, one defining the members on the line. A
sample is [here](test/fixtures/simple_line.json).  Members can be a `Picker` or a `Checker`.
The input file allows overriding the default parameters defined in
[Picker.Parameters](lib/warehouse_simulator/picker/parameters.ex) and
[Checker.Parameters](lib/warehouse_simulator/checker/parameters.ex).  The other file is a list of
work orders or "pick tickets".  An example is [here](test/fixtures/pick_tickets.tsv). Each line is
a separate ticket where items and quantities are separated by tabs.

The output of the simulation is a list of total simulation time to run the entire line as well
as a list of how much each member spent idle.  For example:

```bash
$ mix escript.build
Compiling 4 files (.ex)
Generated escript _build/dev/warehouse_simulator with MIX_ENV=dev
$ _build/dev/warehouse_simulator test/fixtures/simple_line.json test/fixtures/pick_tickets.tsv
Elapsed: 36.0
Idle times:
5.0 (14.0%)
13.0 (36.0%)
18.0 (50.0%)
```
