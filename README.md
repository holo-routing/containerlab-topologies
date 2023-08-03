# Containerlab topologies

Here you will find a collection of pre-configured network topologies that can be used for protocol labbing and software interoperability testing.

If you're new to containerlab, you can quickly get started by visiting the [official documentation](https://containerlab.dev/quickstart/).

### Organization

This repository is organized into directories, each representing a unique network topology.
Within each directory, you'll find configuration files for different routing stacks, including:

* Holo (open source)
* FRRouting (open source)
* BIRD (open source)
* SR Linux (Nokia)
* cEOS (Arista)

Every topology includes configuration files for container images that support the specific protocol features used within the topology.
For example, the *ospfv3-sr* directory contains only Holo configuration files because Holo is the only routing stack that supports Segment Routing for OSPFv3.

As part of future plans, the topologies will be expanded to include configurations for other vendors, such as IOS-XR and Junos.

By default, all topologies use Holo in all routers. However, you have the flexibility to customize the topology files and experiment with different container images on different routers.

### Running a topology

To deploy a topology, use the following command:
```sh
$ sudo containerlab deploy -c --topo <path-to-topology.yml>
```

**NOTE**: Some topologies use bridge interfaces that require explicit creation since containerlab does not handle that. To create the necessary bridge interface, use the following commands:
```sh
$ sudo ip link add br1 type bridge
$ sudo ip link set dev br1 up
```

The topology initialization may take a few seconds, depending on the router images used. Once complete, you will see an output similar to the following, indicating the status and management addresses of all virtual routers:
```sh
+---+-----------------+--------------+-------------------------------+-------+---------+----------------+----------------------+
| # |      Name       | Container ID |             Image             | Kind  |  State  |  IPv4 Address  |     IPv6 Address     |
+---+-----------------+--------------+-------------------------------+-------+---------+----------------+----------------------+
| 1 | clab-ospfv2-rt1 | 2746124fb722 | ghcr.io/rwestphal/holo:latest | linux | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
| 2 | clab-ospfv2-rt2 | 83946a575b4d | ghcr.io/rwestphal/holo:latest | linux | running | 172.20.20.7/24 | 2001:172:20:20::7/64 |
| 3 | clab-ospfv2-rt3 | 55d6b054af64 | ghcr.io/rwestphal/holo:latest | linux | running | 172.20.20.4/24 | 2001:172:20:20::4/64 |
| 4 | clab-ospfv2-rt4 | 173125d65817 | ghcr.io/rwestphal/holo:latest | linux | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
| 5 | clab-ospfv2-rt5 | d7051036115c | ghcr.io/rwestphal/holo:latest | linux | running | 172.20.20.5/24 | 2001:172:20:20::5/64 |
| 6 | clab-ospfv2-rt6 | 64b6e768bca1 | ghcr.io/rwestphal/holo:latest | linux | running | 172.20.20.6/24 | 2001:172:20:20::6/64 |
+---+-----------------+--------------+-------------------------------+-------+---------+----------------+----------------------+
```

To access any router, you can use the following command (replacing bash with your desired shell or CLI):
```sh
$ sudo docker exec -it clab-ospfv2-rt1 bash
```

To stop the topology, use the following command:
```sh
$ sudo containerlab destroy --all
```

Feel free to explore the different topologies and experiment with various configurations. Happy labbing!
