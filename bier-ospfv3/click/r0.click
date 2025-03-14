cfg :: HTTPServer;

bift0 :: LookupBierTable(BIFT_ID 0x01234, BFR_ID 1, IFACE eth0:2, IFACE eth1:3);
bift1 :: LookupBierTable(BIFT_ID 0x5, BFR_ID 1, IFACE eth0:2, IFACE eth1:3);

lo :: FromDevice(lo, SNIFFER false, PROMISC true);
eth0 :: FromDevice(eth0, SNIFFER false, PROMISC true);
eth1 :: FromDevice(eth1, SNIFFER false, PROMISC true);
lo_out :: Queue -> ToDevice(lo);
eth0_out :: Queue -> ToDevice(eth0);
eth1_out :: Queue -> ToDevice(eth1);

eth0_nds :: IP6NDSolicitor(fc00::, aa:c1:ab:07:ba:00);
ndadv_eth0 :: IP6NDAdvertiser(fc00::/128 aa:c1:ab:07:ba:00);
eth1_nds :: IP6NDSolicitor(fc00::, aa:c1:ab:07:ba:01);
ndadv_eth1 :: IP6NDAdvertiser(fc00::/128 aa:c1:ab:07:ba:01);

eth0 -> ndp_cl_eth0 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
// Received NDP Solicitation, reply with NDP Advertisement
ndp_cl_eth0[0] -> ndadv_eth0 -> eth0_out;
// Received NDP Advertisement, save the mapping
ndp_cl_eth0[1] -> [1] eth0_nds;

eth1 -> ndp_cl_eth1 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
ndp_cl_eth1[0] -> ndadv_eth1 -> eth1_out;
ndp_cl_eth1[1] -> [1] eth1_nds;

// Check BIER packet validity then send it to the correct BIFT
lo, ndp_cl_eth0[2], ndp_cl_eth1[2]
	-> CheckIP6Header(OFFSET 14)
	-> CheckBIERin6Header
	-> CheckBIERHeader
	-> IP6Print("here", CONTENTS true, NBYTES 2000)
	-> Strip(14)
	-> Print
	-> bift_cl :: Classifier(
		40/01234?%fffff0,
		40/05,
		-
	);

bift_cl[0] -> bift0;
bift_cl[1] -> bift1;
bift_cl[2] -> Print("Unknown BIFT id") -> Discard;

bift0[0], bift1[0] -> Print("drop") -> Discard;
bift0[1], bift1[1] -> Print("lo") -> lo_out;
bift0[2], bift1[2] -> [0] eth0_nds [0] -> Print("eth0") -> eth0_out;
bift0[3], bift1[3] -> [0] eth1_nds [0] -> Print("eth1") -> eth1_out;
