[Variables]
@Include=#@#Icons.inc
[MeterSection1]
Meter=String
Text=Contractors
FontFace=Segoe UI
FontSize=16
FontColor=130,180,255,255
FontWeight=700
StringStyle=Bold
AntiAlias=1
ClipString=1
X=15
Y=12
W=340
H=30
LeftMouseDoubleClickAction=[!SetVariable InputX "15"][!SetVariable InputY "[MeterSection1:Y]"][!SetVariable EditIndex "1"][!SetVariable EditDefault "Contractors"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 3-4"]
[MeterSectionAdd1]
Meter=String
Text=#icon-add#
FontFace=Material Icons
FontSize=12
FontColor=130,180,255,255
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 75)
Y=r
ToolTipText=Add task to this section
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDesc3:Y]"][!SetVariable EditIndex "1"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 5-6"]
[MeterSectionEdit1]
Meter=String
Text=#icon-edit#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=4R
Y=r
LeftMouseUpAction=[!SetVariable InputX "15"][!SetVariable InputY "[MeterSection1:Y]"][!SetVariable EditIndex "1"][!SetVariable EditDefault "Contractors"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 3-4"]
[MeterSectionDel1]
Meter=String
Text=#icon-delete#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=4R
Y=r
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(1)"][!Refresh][!Refresh]
[MeterSectionLine1]
Meter=Image
SolidColor=80,130,220,80
X=15
Y=2R
W=390
H=1
[MeterCheck2]
Meter=String
Text=#icon-check#
FontFace=Material Icons
FontSize=14
FontColor=220,225,230,255
SolidColor=0,0,0,1
AntiAlias=1
X=15
Y=6R
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleCheck(2)"][!Refresh][!Refresh]
[MeterName2]
Meter=String
Text=Windows
FontFace=Segoe UI
FontSize=13
FontColor=220,225,230,255
FontWeight=600
AntiAlias=1
ClipString=1
X=40
Y=r
W=300
H=24
[MeterTaskAddSub2]
Meter=String
Text=#icon-subitem#
FontFace=Material Icons
FontSize=11
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 55)
Y=r
H=24
ToolTipText=Add subitem
LeftMouseUpAction=[!SetVariable InputX "45"][!SetVariable InputY "[MeterDescEdit2:Y]"][!SetVariable EditIndex "2"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 7-8"]
[MeterTaskDel2]
Meter=String
Text=#icon-delete#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 30)
Y=r
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(2)"][!Refresh][!Refresh]
[MeterDesc2_1]
Meter=String
FontFace=Segoe UI
FontSize=10
AntiAlias=1
ClipString=1
SolidColor=0,0,0,1
X=40
Y=R
W=340
H=20
Text=Markey. ETA 3/24
FontColor=160,165,175,200
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDesc2_1:Y]"][!SetVariable EditIndex "2"][!SetVariable EditDefault "Markey. ETA 3/24"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]
[MeterDescEdit2]
Meter=String
Text=#icon-edit#
FontFace=Material Icons
FontSize=10
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 35)
Y=r
H=20
ToolTipText=Edit description
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDesc2_1:Y]"][!SetVariable EditIndex "2"][!SetVariable EditDefault "Markey. ETA 3/24"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]
[MeterCheck3]
Meter=String
Text=#icon-check#
FontFace=Material Icons
FontSize=14
FontColor=220,225,230,255
SolidColor=0,0,0,1
AntiAlias=1
X=15
Y=6R
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleCheck(3)"][!Refresh][!Refresh]
[MeterName3]
Meter=String
Text=Closet
FontFace=Segoe UI
FontSize=13
FontColor=220,225,230,255
FontWeight=600
AntiAlias=1
ClipString=1
X=40
Y=r
W=300
H=24
[MeterTaskAddSub3]
Meter=String
Text=#icon-subitem#
FontFace=Material Icons
FontSize=11
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 55)
Y=r
H=24
ToolTipText=Add subitem
LeftMouseUpAction=[!SetVariable InputX "45"][!SetVariable InputY "[MeterDesc3:Y]"][!SetVariable EditIndex "3"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 7-8"]
[MeterTaskDel3]
Meter=String
Text=#icon-delete#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 30)
Y=r
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(3)"][!Refresh][!Refresh]
[MeterDesc3]
Meter=String
Text=add note...
FontFace=Segoe UI
FontSize=10
FontColor=100,105,115,100
AntiAlias=1
ClipString=1
SolidColor=0,0,0,1
X=40
Y=R
W=360
H=20
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDesc3:Y]"][!SetVariable EditIndex "3"][!SetVariable EditDefault ""][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]
[MeterSection4]
Meter=String
Text=Packages
FontFace=Segoe UI
FontSize=16
FontColor=130,180,255,255
FontWeight=700
StringStyle=Bold
AntiAlias=1
ClipString=1
X=15
Y=18R
W=340
H=30
LeftMouseDoubleClickAction=[!SetVariable InputX "15"][!SetVariable InputY "[MeterSection4:Y]"][!SetVariable EditIndex "4"][!SetVariable EditDefault "Packages"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 3-4"]
[MeterSectionAdd4]
Meter=String
Text=#icon-add#
FontFace=Material Icons
FontSize=12
FontColor=130,180,255,255
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 75)
Y=r
ToolTipText=Add task to this section
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDescEdit7:Y]"][!SetVariable EditIndex "4"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 5-6"]
[MeterSectionEdit4]
Meter=String
Text=#icon-edit#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=4R
Y=r
LeftMouseUpAction=[!SetVariable InputX "15"][!SetVariable InputY "[MeterSection4:Y]"][!SetVariable EditIndex "4"][!SetVariable EditDefault "Packages"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 3-4"]
[MeterSectionDel4]
Meter=String
Text=#icon-delete#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=4R
Y=r
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(4)"][!Refresh][!Refresh]
[MeterSectionLine4]
Meter=Image
SolidColor=80,130,220,80
X=15
Y=2R
W=390
H=1
[MeterCheck5]
Meter=String
Text=#icon-check#
FontFace=Material Icons
FontSize=14
FontColor=220,225,230,255
SolidColor=0,0,0,1
AntiAlias=1
X=15
Y=6R
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleCheck(5)"][!Refresh][!Refresh]
[MeterName5]
Meter=String
Text=stickers
FontFace=Segoe UI
FontSize=13
FontColor=220,225,230,255
FontWeight=600
AntiAlias=1
ClipString=1
X=40
Y=r
W=300
H=24
[MeterTaskAddSub5]
Meter=String
Text=#icon-subitem#
FontFace=Material Icons
FontSize=11
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 55)
Y=r
H=24
ToolTipText=Add subitem
LeftMouseUpAction=[!SetVariable InputX "45"][!SetVariable InputY "[MeterDescEdit5:Y]"][!SetVariable EditIndex "5"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 7-8"]
[MeterTaskDel5]
Meter=String
Text=#icon-delete#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 30)
Y=r
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(5)"][!Refresh][!Refresh]
[MeterDesc5_1]
Meter=String
FontFace=Segoe UI
FontSize=10
AntiAlias=1
ClipString=1
SolidColor=0,0,0,1
X=40
Y=R
W=340
H=20
Text=shopify.com/35444162605/account/orders/01532207...
FontColor=100,160,255,255
StringStyle=Underline
LeftMouseUpAction=["https://shopify.com/35444162605/account/orders/015322072a24446cc80f28b187dc2ae7?locale=en-US"]
ToolTipText=https://shopify.com/35444162605/account/orders/015322072a24446cc80f28b187dc2ae7?locale=en-US
[MeterDescEdit5]
Meter=String
Text=#icon-edit#
FontFace=Material Icons
FontSize=10
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 35)
Y=r
H=20
ToolTipText=Edit description
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDesc5_1:Y]"][!SetVariable EditIndex "5"][!SetVariable EditDefault "https://shopify.com/35444162605/account/orders/015322072a24446cc80f28b187dc2ae7?locale=en-US"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]
[MeterCheck6]
Meter=String
Text=#icon-check#
FontFace=Material Icons
FontSize=14
FontColor=220,225,230,255
SolidColor=0,0,0,1
AntiAlias=1
X=15
Y=6R
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleCheck(6)"][!Refresh][!Refresh]
[MeterName6]
Meter=String
Text=Bully sticks
FontFace=Segoe UI
FontSize=13
FontColor=220,225,230,255
FontWeight=600
AntiAlias=1
ClipString=1
X=40
Y=r
W=300
H=24
[MeterTaskAddSub6]
Meter=String
Text=#icon-subitem#
FontFace=Material Icons
FontSize=11
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 55)
Y=r
H=24
ToolTipText=Add subitem
LeftMouseUpAction=[!SetVariable InputX "45"][!SetVariable InputY "[MeterDescEdit6:Y]"][!SetVariable EditIndex "6"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 7-8"]
[MeterTaskDel6]
Meter=String
Text=#icon-delete#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 30)
Y=r
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(6)"][!Refresh][!Refresh]
[MeterDesc6_1]
Meter=String
FontFace=Segoe UI
FontSize=10
AntiAlias=1
ClipString=1
SolidColor=0,0,0,1
X=40
Y=R
W=340
H=20
Text=x3e6h.aftership.com/1ZJ74F69YW00553761?_sc_p=li...
FontColor=100,160,255,255
StringStyle=Underline
LeftMouseUpAction=["https://x3e6h.aftership.com/1ZJ74F69YW00553761?_sc_p=lid%3A3f77a8ad6962e291cc94aa9db9a8cee4%2Aseg%3Aaftership-tracking_info_received_to_customer-am_trace_id%3D025004564fdb1fb347e15f721c69f9da%2F0-section_id%3Dorder_tracking%2Amdm%3Aemail"]
ToolTipText=https://x3e6h.aftership.com/1ZJ74F69YW00553761?_sc_p=lid%3A3f77a8ad6962e291cc94aa9db9a8cee4%2Aseg%3Aaftership-tracking_info_received_to_customer-am_trace_id%3D025004564fdb1fb347e15f721c69f9da%2F0-section_id%3Dorder_tracking%2Amdm%3Aemail
[MeterDescEdit6]
Meter=String
Text=#icon-edit#
FontFace=Material Icons
FontSize=10
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 35)
Y=r
H=20
ToolTipText=Edit description
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDesc6_1:Y]"][!SetVariable EditIndex "6"][!SetVariable EditDefault "https://x3e6h.aftership.com/1ZJ74F69YW00553761?_sc_p=lid%3A3f77a8ad6962e291cc94aa9db9a8cee4%2Aseg%3Aaftership-tracking_info_received_to_customer-am_trace_id%3D025004564fdb1fb347e15f721c69f9da%2F0-section_id%3Dorder_tracking%2Amdm%3Aemail"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]
[MeterCheck7]
Meter=String
Text=#icon-check#
FontFace=Material Icons
FontSize=14
FontColor=220,225,230,255
SolidColor=0,0,0,1
AntiAlias=1
X=15
Y=6R
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleCheck(7)"][!Refresh][!Refresh]
[MeterName7]
Meter=String
Text=Arbortech pants
FontFace=Segoe UI
FontSize=13
FontColor=220,225,230,255
FontWeight=600
AntiAlias=1
ClipString=1
X=40
Y=r
W=300
H=24
[MeterTaskAddSub7]
Meter=String
Text=#icon-subitem#
FontFace=Material Icons
FontSize=11
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 55)
Y=r
H=24
ToolTipText=Add subitem
LeftMouseUpAction=[!SetVariable InputX "45"][!SetVariable InputY "[MeterDescEdit7:Y]"][!SetVariable EditIndex "7"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 7-8"]
[MeterTaskDel7]
Meter=String
Text=#icon-delete#
FontFace=Material Icons
FontSize=12
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 30)
Y=r
H=24
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(7)"][!Refresh][!Refresh]
[MeterDesc7_1]
Meter=String
FontFace=Segoe UI
FontSize=10
AntiAlias=1
ClipString=1
SolidColor=0,0,0,1
X=40
Y=R
W=340
H=20
Text=# www.dhl.com/us-en/home/tracking.html?locale=tru...
FontColor=100,160,255,255
StringStyle=Underline
LeftMouseUpAction=["https://www.dhl.com/us-en/home/tracking.html?locale=true&tracking-id=1164198615&submit=1"]
ToolTipText=https://www.dhl.com/us-en/home/tracking.html?locale=true&tracking-id=1164198615&submit=1
[MeterDesc7_2]
Meter=String
FontFace=Segoe UI
FontSize=10
AntiAlias=1
ClipString=1
SolidColor=0,0,0,1
X=40
Y=R
W=340
H=20
Text=# shopify.com/13543407675/account/orders/bc63d85b...
FontColor=100,160,255,255
StringStyle=Underline
LeftMouseUpAction=["https://shopify.com/13543407675/account/orders/bc63d85b3de3877a8910817b9cf732e0?locale=en-US"]
ToolTipText=https://shopify.com/13543407675/account/orders/bc63d85b3de3877a8910817b9cf732e0?locale=en-US
[MeterDescEdit7]
Meter=String
Text=#icon-edit#
FontFace=Material Icons
FontSize=10
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=(420 - 35)
Y=r
H=20
ToolTipText=Edit description
LeftMouseUpAction=[!SetVariable InputX "40"][!SetVariable InputY "[MeterDesc7_1:Y]"][!SetVariable EditIndex "7"][!SetVariable EditDefault "https://www.dhl.com/us-en/home/tracking.html?locale=true&tracking-id=1164198615&submit=1;; https://shopify.com/13543407675/account/orders/bc63d85b3de3877a8910817b9cf732e0?locale=en-US"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]
[MeterAddSection]
Meter=String
Text=+ Section
FontFace=Segoe UI
FontSize=10
FontColor=130,180,255,255
SolidColor=0,0,0,1
AntiAlias=1
X=15
Y=15R
ToolTipText=Add Section
LeftMouseUpAction=[!SetVariable InputX "15"][!SetVariable InputY "[MeterAddSection:Y]"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 1-2"]
[MeterUndo]
Meter=String
Text=#icon-undo#
FontFace=Material Icons
FontSize=14
FontColor=180,185,195,220
SolidColor=0,0,0,1
AntiAlias=1
X=6R
Y=r
ToolTipText=Undo Delete
LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "UndoDelete()"][!Refresh][!Refresh]
[MeterBottomPad]
Meter=Image
SolidColor=0,0,0,0
X=0
Y=10R
W=1
H=5