cfg :: HTTPServer;

bift0 :: LookupBierTable(BIFT_ID 0x01234, BFR_ID 3, IFACE eth0:2, IFACE eth1:3, IFACE eth2:4, IFACE eth3:5);

lo :: FromDevice(lo, SNIFFER false, PROMISC true);
eth0 :: FromDevice(eth0, SNIFFER false, PROMISC true);
eth1 :: FromDevice(eth1, SNIFFER false, PROMISC true);
eth2 :: FromDevice(eth2, SNIFFER false, PROMISC true);
eth3 :: FromDevice(eth3, SNIFFER false, PROMISC true);
lo_out :: Queue -> ToDevice(lo);
eth0_out :: Queue -> ToDevice(eth0);
eth1_out :: Queue -> ToDevice(eth1);
eth2_out :: Queue -> ToDevice(eth2);
eth3_out :: Queue -> ToDevice(eth3);

eth0_nds :: IP6NDSolicitor(fc00::2, aa:c1:ab:07:ba:06);
ndadv_eth0 :: IP6NDAdvertiser(fc00::2/128 aa:c1:ab:07:ba:06);
eth1_nds :: IP6NDSolicitor(fc00::2, aa:c1:ab:07:ba:07);
ndadv_eth1 :: IP6NDAdvertiser(fc00::2/128 aa:c1:ab:07:ba:07);
eth2_nds :: IP6NDSolicitor(fc00::2, aa:c1:ab:07:ba:08);
ndadv_eth2 :: IP6NDAdvertiser(fc00::2/128 aa:c1:ab:07:ba:08);
eth3_nds :: IP6NDSolicitor(fc00::2, aa:c1:ab:07:ba:09);
ndadv_eth4 :: IP6NDAdvertiser(fc00::2/128 aa:c1:ab:07:ba:09);

eth0 -> ndp_cl_eth0 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
// Received NDP Solicitation, reply with NDP Advertisement
ndp_cl_eth0[0] -> ndadv_eth0 -> eth0_out;
// Received NDP Advertisement, save the mapping
ndp_cl_eth0[1] -> [1] eth0_nds;

eth1 -> ndp_cl_eth1 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
ndp_cl_eth1[0] -> ndadv_eth1 -> eth1_out;
ndp_cl_eth1[1] -> [1] eth1_nds;

eth2 -> ndp_cl_eth2 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
ndp_cl_eth2[0] -> ndadv_eth2 -> eth2_out;
ndp_cl_eth2[1] -> [1] eth2_nds;

eth3 -> ndp_cl_eth3 :: Classifier(12/86dd 20/3aff 54/87, 12/86dd 20/3aff 54/88, 12/86dd);
ndp_cl_eth3[0] -> ndadv_eth3 -> eth3_out;
ndp_cl_eth3[1] -> [1] eth3_nds;

lo, ndp_cl_eth0[2], ndp_cl_eth1[2], ndp_cl_eth2[2], ndp_cl_eth3[2]
    ->  CheckIP6Header(OFFSET 14)
	-> CheckBIERin6Header
	-> CheckBIERHeader
	-> IP6Print(CONTENTS true)
	-> Strip(14)
	-> Print
	-> bift0;

bift0[0] -> Print("drop") -> Discard;
bift0[1] -> Print("lo") -> lo_out;
bift0[2] -> [0] eth0_nds [0] -> Print("eth0") -> eth0_out;
bift0[3] -> [0] eth1_nds [0] -> Print("eth1") -> eth1_out;
bift0[4] -> [0] eth2_nds [0] -> Print("eth2") -> eth2_out;
bift0[5] -> [0] eth3_nds [0] -> Print("eth3") -> eth3_out;
