/************************************************************\
**	Copyright (c) 2012-2025 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Build time: Sep 15 2025 15:04:03
**	TD version	:	6.2.168116
************************************************************/
module ChipWatcher_ov5640
(
  input   [0:0]                 probe0,
  input   [0:0]                 probe1,
  input   [0:0]                 probe2,
  input   [4:0]                 probe3,
  input   [5:0]                 probe4,
  input   [4:0]                 probe5,
  input                         clk
);

  ChipWatcher_c1d7b979fda0  ChipWatcher_c1d7b979fda0_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .probe4(probe4),
      .probe5(probe5),
      .clk(clk)
  );
endmodule
