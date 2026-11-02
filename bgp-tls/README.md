# Simple demo of BGP over TLS

This demo contains a custom Dockerfile to build beforehand since the feature is not embedded in official containers yet.

Launch the following command before starting the topology.

```console
$ docker build -t holo-runner .
```

Then, start the experiment with:

```console
$ clab redeploy -t topology.yml
```

> Note: the startup of r1 is slighlty delayed, otherwise both routers start too fast and r1 falls in a currently unhandled case.

By running the following command for each node, you should obtain logs looking like the ones provided below.
The [`cap.txt`](cap.txt) file contains, in textual form, a packet capture on r0 of the experiment whose logs are provided below.

```console
$ docker logs -f clab-bgp-tls-{node}
```

Sample logs for r0:
```txt
2026-11-02T22:00:36.699517Z  INFO starting up
2026-11-02T22:00:36.808297Z  WARN failed to set MPLS platform labels error=no such sysctl: net.mpls.platform_labels
2026-11-02T22:00:41.612468Z DEBUG northbound: configuration transaction confirmed_timeout=0 changes={
  "ietf-interfaces:interfaces": {
    "@": {
      "yang:operation": "create"
    },
    "interface": [
      {
        "name": "eth0",
        "type": "iana-if-type:ethernetCsmacd",
        "ietf-ip:ipv4": {
          "address": [
            {
              "ip": "10.0.1.1",
              "prefix-length": 30
            }
          ]
        },
        "ietf-ip:ipv6": {}
      },
      {
        "name": "lo",
        "type": "iana-if-type:ethernetCsmacd",
        "ietf-ip:ipv4": {
          "address": [
            {
              "ip": "10.0.1.0",
              "prefix-length": 24
            }
          ]
        },
        "ietf-ip:ipv6": {}
      }
    ]
  },
  "ietf-routing:routing": {
    "@": {
      "yang:operation": "create"
    },
    "control-plane-protocols": {
      "control-plane-protocol": [
        {
          "type": "ietf-bgp:bgp",
          "name": "main",
          "ietf-bgp:bgp": {
            "global": {
              "as": 65001,
              "identifier": "10.0.1.1",
              "afi-safis": {
                "afi-safi": [
                  {
                    "name": "iana-bgp-types:ipv4-unicast",
                    "enabled": true,
                    "apply-policy": {
                      "import-policy": [
                        "EXPORT"
                      ],
                      "@import-policy": [
                        {
                          "yang:value": ""
                        }
                      ]
                    },
                    "ipv4-unicast": {
                      "holo-bgp:redistribution": [
                        {
                          "type": "ietf-routing:direct"
                        }
                      ]
                    }
                  }
                ]
              }
            },
            "neighbors": {
              "neighbor": [
                {
                  "remote-address": "10.0.1.2",
                  "enabled": true,
                  "peer-as": 65002,
                  "transport": {
                    "local-address": "10.0.1.1",
                    "holo-bgp-tls:tls": {
                      "cert": "/etc/holo/router.cert.pem",
                      "pkey": "/etc/holo/router.key",
                      "ca-chain": "/etc/holo/ca.cert.pem",
                      "sni": "r1.asn65002.example.com"
                    }
                  },
                  "afi-safis": {
                    "afi-safi": [
                      {
                        "name": "iana-bgp-types:ipv4-unicast",
                        "enabled": true,
                        "apply-policy": {
                          "import-policy": [
                            "IMPORT"
                          ],
                          "@import-policy": [
                            {
                              "yang:value": ""
                            }
                          ],
                          "default-export-policy": "accept-route"
                        }
                      }
                    ]
                  },
                  "holo-bgp:trace-options": {
                    "flag": [
                      {
                        "name": "events"
                      },
                      {
                        "name": "packets-all"
                      }
                    ]
                  }
                }
              ]
            }
          }
        }
      ]
    }
  },
  "ietf-routing-policy:routing-policy": {
    "@": {
      "yang:operation": "create"
    },
    "defined-sets": {
      "prefix-sets": {
        "prefix-set": [
          {
            "name": "MY_PREFIX",
            "mode": "ipv4",
            "prefixes": {
              "prefix-list": [
                {
                  "ip-prefix": "10.0.1.0/24",
                  "mask-length-lower": 24,
                  "mask-length-upper": 24
                }
              ]
            }
          },
          {
            "name": "THEIR_PREFIX",
            "mode": "ipv4",
            "prefixes": {
              "prefix-list": [
                {
                  "ip-prefix": "10.0.2.0/24",
                  "mask-length-lower": 24,
                  "mask-length-upper": 24
                }
              ]
            }
          }
        ]
      }
    },
    "policy-definitions": {
      "policy-definition": [
        {
          "name": "EXPORT",
          "statements": {
            "statement": [
              {
                "@": {
                  "yang:key": [null]
                },
                "name": "1",
                "conditions": {
                  "match-prefix-set": {
                    "prefix-set": "MY_PREFIX"
                  }
                },
                "actions": {
                  "policy-result": "accept-route"
                }
              }
            ]
          }
        },
        {
          "name": "IMPORT",
          "statements": {
            "statement": [
              {
                "@": {
                  "yang:key": [null]
                },
                "name": "1",
                "conditions": {
                  "match-prefix-set": {
                    "prefix-set": "THEIR_PREFIX"
                  }
                },
                "actions": {
                  "policy-result": "accept-route"
                }
              }
            ]
          }
        }
      ]
    }
  }
}

2026-11-02T22:00:41.614320Z DEBUG protocol{type=bgp instance=main}: instance created
2026-11-02T22:00:41.615462Z DEBUG protocol{type=bgp instance=main}: starting instance
2026-11-02T22:00:41.615978Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: state transition old_state=Idle new_state=Connect
2026-11-02T22:00:41.616001Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: state transition old_state=Connect new_state=Idle
2026-11-02T22:00:42.618334Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=Timer(AutoStart)
2026-11-02T22:00:42.618433Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: state transition old_state=Idle new_state=Connect
2026-11-02T22:00:44.667540Z  WARN protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}: failed to establish TCP connection error=Host is unreachable (os error 113)
2026-11-02T22:00:47.793484Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=Connected(TlsStream(Server(TlsStream { io: TcpStream { addr: 10.0.1.1:179, peer: 10.0.1.2:39917, fd: 15 }, session: ServerConnection, state: Stream, need_flush: false, error: None })), TcpConnInfo { local_addr: 10.0.1.1, local_port: 179, remote_addr: 10.0.1.2, remote_port: 39917 }, Local)
2026-11-02T22:00:47.793668Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:output: message data={"Open":{"version":4,"my_as":65001,"holdtime":90,"identifier":"10.0.1.1","capabilities":[{"MultiProtocol":{"afi":"Ipv4","safi":"Unicast"}},{"FourOctetAsNumber":{"asn":65001}},"RouteRefresh"]}}
2026-11-02T22:00:47.793704Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: state transition old_state=Connect new_state=OpenSent
2026-11-02T22:00:47.793788Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:input: message data={"Open":{"version":4,"my_as":65002,"holdtime":90,"identifier":"10.0.1.2","capabilities":[{"MultiProtocol":{"afi":"Ipv4","safi":"Unicast"}},{"FourOctetAsNumber":{"asn":65002}},"RouteRefresh"]}}
2026-11-02T22:00:47.793828Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=RcvdOpen(OpenMsg { version: 4, my_as: 65002, holdtime: 90, identifier: 10.0.1.2, capabilities: {MultiProtocol { afi: Ipv4, safi: Unicast }, FourOctetAsNumber { asn: 65002 }, RouteRefresh} })
2026-11-02T22:00:47.793899Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:output: message data={"Keepalive":{}}
2026-11-02T22:00:47.794021Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: state transition old_state=OpenSent new_state=OpenConfirm
2026-11-02T22:00:47.794173Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:input: message data={"Keepalive":{}}
2026-11-02T22:00:47.794189Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=RcvdKalive
2026-11-02T22:00:47.794240Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: state transition old_state=OpenConfirm new_state=Established
2026-11-02T22:00:47.797367Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:output: message data={"Update":{"reach":{"prefixes":["10.0.1.0/24"],"nexthop":"10.0.1.1"},"attrs":{"base":{"origin":"Incomplete","as_path":{"segments":[{"seg_type":"Sequence","members":[65001]}]},"nexthop":"10.0.1.1"}}}}
2026-11-02T22:00:47.797589Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:input: message data={"Update":{"reach":{"prefixes":["10.0.2.0/24"],"nexthop":"10.0.1.2"},"attrs":{"base":{"origin":"Incomplete","as_path":{"segments":[{"seg_type":"Sequence","members":[65002]}]}}}}}
2026-11-02T22:00:47.797629Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=RcvdUpdate
2026-11-02T22:00:47.797899Z DEBUG routing: nexthop tracking add addr=10.0.1.2
2026-11-02T22:01:17.795729Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:output: message data={"Keepalive":{}}
2026-11-02T22:01:17.796340Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:input: message data={"Keepalive":{}}
2026-11-02T22:01:17.796423Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=RcvdKalive
2026-11-02T22:01:47.795265Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:output: message data={"Keepalive":{}}
2026-11-02T22:01:47.796048Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:input: message data={"Keepalive":{}}
2026-11-02T22:01:47.796156Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=RcvdKalive
2026-11-02T22:02:17.795764Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:output: message data={"Keepalive":{}}
2026-11-02T22:02:17.796003Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:input: message data={"Keepalive":{}}
2026-11-02T22:02:17.796096Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=RcvdKalive
2026-11-02T22:02:47.796369Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:output: message data={"Keepalive":{}}
2026-11-02T22:02:47.796671Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:input: message data={"Keepalive":{}}
2026-11-02T22:02:47.796771Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.2}:fsm: event event=RcvdKalive
```

Sample logs for r1:
```txt
2026-11-02T22:00:41.905223Z  INFO starting up
2026-11-02T22:00:41.973638Z  WARN failed to set MPLS platform labels error=no such sysctl: net.mpls.platform_labels
2026-11-02T22:00:46.786370Z DEBUG northbound: configuration transaction confirmed_timeout=0 changes={
  "ietf-interfaces:interfaces": {
    "@": {
      "yang:operation": "create"
    },
    "interface": [
      {
        "name": "eth0",
        "type": "iana-if-type:ethernetCsmacd",
        "ietf-ip:ipv4": {
          "address": [
            {
              "ip": "10.0.1.2",
              "prefix-length": 30
            }
          ]
        },
        "ietf-ip:ipv6": {}
      },
      {
        "name": "lo",
        "type": "iana-if-type:ethernetCsmacd",
        "ietf-ip:ipv4": {
          "address": [
            {
              "ip": "10.0.2.0",
              "prefix-length": 24
            }
          ]
        },
        "ietf-ip:ipv6": {}
      }
    ]
  },
  "ietf-routing:routing": {
    "@": {
      "yang:operation": "create"
    },
    "control-plane-protocols": {
      "control-plane-protocol": [
        {
          "type": "ietf-bgp:bgp",
          "name": "main",
          "ietf-bgp:bgp": {
            "global": {
              "as": 65002,
              "identifier": "10.0.1.2",
              "afi-safis": {
                "afi-safi": [
                  {
                    "name": "iana-bgp-types:ipv4-unicast",
                    "enabled": true,
                    "apply-policy": {
                      "import-policy": [
                        "EXPORT"
                      ],
                      "@import-policy": [
                        {
                          "yang:value": ""
                        }
                      ]
                    },
                    "ipv4-unicast": {
                      "holo-bgp:redistribution": [
                        {
                          "type": "ietf-routing:direct"
                        }
                      ]
                    }
                  }
                ]
              }
            },
            "neighbors": {
              "neighbor": [
                {
                  "remote-address": "10.0.1.1",
                  "enabled": true,
                  "peer-as": 65001,
                  "transport": {
                    "local-address": "10.0.1.2",
                    "holo-bgp-tls:tls": {
                      "cert": "/etc/holo/router.cert.pem",
                      "pkey": "/etc/holo/router.key",
                      "ca-chain": "/etc/holo/ca.cert.pem",
                      "sni": "r0.asn65001.example.com"
                    }
                  },
                  "afi-safis": {
                    "afi-safi": [
                      {
                        "name": "iana-bgp-types:ipv4-unicast",
                        "enabled": true,
                        "apply-policy": {
                          "import-policy": [
                            "IMPORT"
                          ],
                          "@import-policy": [
                            {
                              "yang:value": ""
                            }
                          ],
                          "default-export-policy": "accept-route"
                        }
                      }
                    ]
                  },
                  "holo-bgp:trace-options": {
                    "flag": [
                      {
                        "name": "events"
                      },
                      {
                        "name": "packets-all"
                      }
                    ]
                  }
                }
              ]
            }
          }
        }
      ]
    }
  },
  "ietf-routing-policy:routing-policy": {
    "@": {
      "yang:operation": "create"
    },
    "defined-sets": {
      "prefix-sets": {
        "prefix-set": [
          {
            "name": "MY_PREFIX",
            "mode": "ipv4",
            "prefixes": {
              "prefix-list": [
                {
                  "ip-prefix": "10.0.2.0/24",
                  "mask-length-lower": 24,
                  "mask-length-upper": 24
                }
              ]
            }
          },
          {
            "name": "THEIR_PREFIX",
            "mode": "ipv4",
            "prefixes": {
              "prefix-list": [
                {
                  "ip-prefix": "10.0.1.0/24",
                  "mask-length-lower": 24,
                  "mask-length-upper": 24
                }
              ]
            }
          }
        ]
      }
    },
    "policy-definitions": {
      "policy-definition": [
        {
          "name": "EXPORT",
          "statements": {
            "statement": [
              {
                "@": {
                  "yang:key": [null]
                },
                "name": "1",
                "conditions": {
                  "match-prefix-set": {
                    "prefix-set": "MY_PREFIX"
                  }
                },
                "actions": {
                  "policy-result": "accept-route"
                }
              }
            ]
          }
        },
        {
          "name": "IMPORT",
          "statements": {
            "statement": [
              {
                "@": {
                  "yang:key": [null]
                },
                "name": "1",
                "conditions": {
                  "match-prefix-set": {
                    "prefix-set": "THEIR_PREFIX"
                  }
                },
                "actions": {
                  "policy-result": "accept-route"
                }
              }
            ]
          }
        }
      ]
    }
  }
}

2026-11-02T22:00:46.787389Z DEBUG protocol{type=bgp instance=main}: instance created
2026-11-02T22:00:46.788547Z DEBUG protocol{type=bgp instance=main}: starting instance
2026-11-02T22:00:46.789043Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: state transition old_state=Idle new_state=Connect
2026-11-02T22:00:46.789066Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: state transition old_state=Connect new_state=Idle
2026-11-02T22:00:47.790447Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=Timer(AutoStart)
2026-11-02T22:00:47.790501Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: state transition old_state=Idle new_state=Connect
2026-11-02T22:00:47.793267Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=Connected(TlsStream(Client(TlsStream { io: TcpStream { addr: 10.0.1.2:39917, peer: 10.0.1.1:179, fd: 15 }, session: ClientConnection, state: Stream, need_flush: false, error: None })), TcpConnInfo { local_addr: 10.0.1.2, local_port: 39917, remote_addr: 10.0.1.1, remote_port: 179 }, Local)
2026-11-02T22:00:47.793372Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:output: message data={"Open":{"version":4,"my_as":65002,"holdtime":90,"identifier":"10.0.1.2","capabilities":[{"MultiProtocol":{"afi":"Ipv4","safi":"Unicast"}},{"FourOctetAsNumber":{"asn":65002}},"RouteRefresh"]}}
2026-11-02T22:00:47.793421Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: state transition old_state=Connect new_state=OpenSent
2026-11-02T22:00:47.793856Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:input: message data={"Open":{"version":4,"my_as":65001,"holdtime":90,"identifier":"10.0.1.1","capabilities":[{"MultiProtocol":{"afi":"Ipv4","safi":"Unicast"}},{"FourOctetAsNumber":{"asn":65001}},"RouteRefresh"]}}
2026-11-02T22:00:47.793891Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=RcvdOpen(OpenMsg { version: 4, my_as: 65001, holdtime: 90, identifier: 10.0.1.1, capabilities: {MultiProtocol { afi: Ipv4, safi: Unicast }, FourOctetAsNumber { asn: 65001 }, RouteRefresh} })
2026-11-02T22:00:47.793908Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:output: message data={"Keepalive":{}}
2026-11-02T22:00:47.793951Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: state transition old_state=OpenSent new_state=OpenConfirm
2026-11-02T22:00:47.794160Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:input: message data={"Keepalive":{}}
2026-11-02T22:00:47.794174Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=RcvdKalive
2026-11-02T22:00:47.794189Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: state transition old_state=OpenConfirm new_state=Established
2026-11-02T22:00:47.797354Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:output: message data={"Update":{"reach":{"prefixes":["10.0.2.0/24"],"nexthop":"10.0.1.2"},"attrs":{"base":{"origin":"Incomplete","as_path":{"segments":[{"seg_type":"Sequence","members":[65002]}]},"nexthop":"10.0.1.2"}}}}
2026-11-02T22:00:47.797559Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:input: message data={"Update":{"reach":{"prefixes":["10.0.1.0/24"],"nexthop":"10.0.1.1"},"attrs":{"base":{"origin":"Incomplete","as_path":{"segments":[{"seg_type":"Sequence","members":[65001]}]}}}}}
2026-11-02T22:00:47.797574Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=RcvdUpdate
2026-11-02T22:00:47.797856Z DEBUG routing: nexthop tracking add addr=10.0.1.1
2026-11-02T22:01:17.795176Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:output: message data={"Keepalive":{}}
2026-11-02T22:01:17.796340Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:input: message data={"Keepalive":{}}
2026-11-02T22:01:17.796422Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=RcvdKalive
2026-11-02T22:01:47.795448Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:output: message data={"Keepalive":{}}
2026-11-02T22:01:47.796130Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:input: message data={"Keepalive":{}}
2026-11-02T22:01:47.796270Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=RcvdKalive
2026-11-02T22:02:17.795320Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:output: message data={"Keepalive":{}}
2026-11-02T22:02:17.796333Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:input: message data={"Keepalive":{}}
2026-11-02T22:02:17.796608Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=RcvdKalive
2026-11-02T22:02:47.795794Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:output: message data={"Keepalive":{}}
2026-11-02T22:02:47.796952Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:input: message data={"Keepalive":{}}
2026-11-02T22:02:47.797048Z DEBUG protocol{type=bgp instance=main}:neighbor{addr=10.0.1.1}:fsm: event event=RcvdKalive
```
