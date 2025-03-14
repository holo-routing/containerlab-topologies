cfg :: HTTPServer;

bift0 :: LookupBierTable(BIFT_ID 0x01234, BFR_ID 5, IFACE eth0:2, IFACE eth1:3);

lo :: FromDevice(lo, SNIFFER false, PROMISC true);
eth0 :: FromDevice(eth0, SNIFFER false, PROMISC true);
eth1 :: FromDevice(eth1, SNIFFER false, PROMISC true);
lo_out :: Queue -> ToDevice(lo);
eth0_out :: Queue -> ToDevice(eth0);
eth1_out :: Queue -> ToDevice(eth1);

eth0_nds :: IP6NDSolicitor(fc00::4, aa:c1:ab:07:ba:0c);
ndadv_eth0 :: IP6NDAdvertiser(fc00::4/128 aa:c1:ab:07:ba:0c);
eth1_nds :: IP6NDSolicitor(fc00::4, aa:c1:ab:07:ba:0d);
ndadv_eth1 :: IP6NDAdvertiser(fc00::4/128 aa:c1:ab:07:ba:0d);

eth0 -> ndp_cl_eth0 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
// Received NDP Solicitation, reply with NDP Advertisement
ndp_cl_eth0[0] -> ndadv_eth0 -> eth0_out;
// Received NDP Advertisement, save the mapping
ndp_cl_eth0[1] -> [1] eth0_nds;

eth1 -> ndp_cl_eth1 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
ndp_cl_eth1[0] -> ndadv_eth1 -> eth1_out;
ndp_cl_eth1[1] -> [1] eth1_nds;

lo, ndp_cl_eth0[2], ndp_cl_eth1[2]
	-> CheckIP6Header(OFFSET 14)
	-> CheckBIERin6Header
	-> CheckBIERHeader
	-> IP6Print(CONTENTS true)
	-> Strip(14)
	-> Print
	-> bift0;

bift0[0] -> Print("drop") -> Discard;
bift0[1] -> Print("lo") -> lo_out;
bift0[2] -> [0] eth0_nds [0] -> eth0_out;
bift0[3] -> [0] eth1_nds [0] -> eth1_out;
