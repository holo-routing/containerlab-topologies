# BIER sample configuration for OSPFv3 and FastClick

This small topology provides an example for configuring the BIER control-plane in OSPFv3 and a BIER data-plane in FastClick.

The FastClick router configures IPv6 Neighbor Discovery to allow IPv6 forwarding, in addition of the BIER lookup table.

## Build

An additional Dockerfile is provided to build the `click` binary embedding the BIER lookup table.

Run the following command to build the additional image:

```console
$ docker build -t holo-runner .
```

> Make sure to compile holod with the `fastclick` feature flag beforehand!

## Usage

You can dump the content of the BIER Routing Information Bases (BIRTs) with the following command:

```console
$ docker exec -it clab-bier-ospfv3-r1 holo-cli -c "sh state xpath /ietf-routing:routing/holo-routing:birts"
```

Here is the expected content for the provided topology:

```json
{
  "ietf-routing:routing": {
    "holo-routing:birts": {
      "birt": [
        {
          "sub-domain-id": 0,
          "bfr-id": [
            {
              "bfr-id": 1,
              "birt-entry": [
                {
                  "bsl": 3,
                  "bfr-prefix": "fc00::",
                  "bfr-nbr": "fe80::a8c1:abff:fee4:2e75"
                }
              ]
            },
            {
              "bfr-id": 3,
              "birt-entry": [
                {
                  "bsl": 3,
                  "bfr-prefix": "fc00::2",
                  "bfr-nbr": "fe80::a8c1:abff:fe9b:703b"
                }
              ]
            },
            {
              "bfr-id": 4,
              "birt-entry": [
                {
                  "bsl": 3,
                  "bfr-prefix": "fc00::3",
                  "bfr-nbr": "fe80::a8c1:abff:fe0f:b9a"
                }
              ]
            },
            {
              "bfr-id": 5,
              "birt-entry": [
                {
                  "bsl": 3,
                  "bfr-prefix": "fc00::4",
                  "bfr-nbr": "fe80::a8c1:abff:fe9b:703b"
                }
              ]
            },
            {
              "bfr-id": 6,
              "birt-entry": [
                {
                  "bsl": 3,
                  "bfr-prefix": "fc00::5",
                  "bfr-nbr": "fe80::a8c1:abff:fe9b:703b"
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
```

You can also dump the content of the BIER Forwarding Table (BIFT) in click with the following command:

```console
$ docker exec -it clab-bier-ospfv3-r1 curl localhost/bift0/table 
```

Here is the expected content for the provided topology:

```json
# Active routes
# BFR-id   BFR-prefix     F-BM    Nexthop    Ifindex
    1    fc00::      0      fe80::a8c1:abff:fee4:2e75      254      eth0
    3    fc00::2      2,4-5      fe80::a8c1:abff:fe9b:703b      268      eth1
    4    fc00::3      3      fe80::a8c1:abff:fe0f:b9a      257      eth3
    5    fc00::4      2,4-5      fe80::a8c1:abff:fe9b:703b      268      eth1
    6    fc00::5      2,4-5      fe80::a8c1:abff:fe9b:703b      268      eth1
```
