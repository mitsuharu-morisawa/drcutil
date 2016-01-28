from math import *
from cnoid.Util import *
from cnoid.DRCUserInterfacePlugin import *
from cnoid.Base import ItemTreeView
import cnoid.Base
import os

# load the base class
execfile(os.path.abspath(os.path.join(os.path.dirname(__file__), "DRCTask.py")))

class CISampleTask(DRCTask):

    def __init__(self, ui):
        DRCTask.__init__(self, ui)
        self.setName("Sample")
        self.setCaption("CI Sample task")

        self.setupTaskScenario()

    def onActivated(self, sequencer):
        self.wasOgMapItemChecked = ItemTreeView.instance().isItemChecked(self.ui.ogMapItem())
        ItemTreeView.instance().checkItem(self.ui.ogMapItem(), False)
        self.wasHeightFieldItemChecked = ItemTreeView.instance().isItemChecked(self.ui.heightFieldItem())
        ItemTreeView.instance().checkItem(self.ui.heightFieldItem(), True)
        self.wasMultiPointCloudItemChecked = ItemTreeView.instance().isItemChecked(self.ui.multiPointCloudItem())
        ItemTreeView.instance().checkItem(self.ui.multiPointCloudItem(), False)

    def onDeactivated(self, sequencer):
        ItemTreeView.instance().checkItem(self.ui.ogMapItem(), self.wasOgMapItemChecked)
        ItemTreeView.instance().checkItem(self.ui.heightFieldItem(), self.wasHeightFieldItemChecked)
        ItemTreeView.instance().checkItem(self.ui.multiPointCloudItem(), self.wasMultiPointCloudItemChecked)
        
    def setupTaskScenario(self):

        #self.addPhase_SeeWorld()

        #self.addPhase_Measure([1.4, 0.0, 0.8], [2.0, 1.0, 1.6])

        self.addPhase_SetWalkDestinationByRobot(1.0, 0, 0)

        self.addPhase_SetWalkDestinationByRobot(-1.0, 0, 0)

        self.addPhase_SetWalkDestinationByRobot(0, 1.0, 0)

        self.addPhase_SetWalkDestinationByRobot(0, -1.0, 0)

        self.addPhase_SetWalkDestinationByRobot(0, 0, 180)

        self.addPhase_SetWalkDestinationByRobot(0, 0, -180)

        #self.addPhase_MeasureAndWaitForHeightFieldUpdated([1.0, 0.0, 0.6], [2.0, 1.0, 1.4])
        self.addPhase_SetWalkDestinationByRobot(5.0, 0, 0)

    def addPhase_MeasureAndWaitForHeightFieldUpdated(self, translation, size):
        self.addPhase("Measurement")
        self.addCommand("Measurement region") \
            .setDefault() \
            .setFunction(lambda : self.setMeasurementRegion(translation, size)) \
            .linkToNextCommand()
        self.addCommand("Skip").linkToNextPhase()
        self.addCommand("Execute the measurement") \
            .setFunction(self.executeMeasurementAndWaitForHeightFieldUpdated) \
            .linkToNextPhase()

    def executeMeasurementAndWaitForHeightFieldUpdated(self, proc):
        self.ui.setPointCloudOffset([[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]])
        self.ui.scan()
        proc.waitForSignal(self.ui.sigHeightFieldUpdated())

    def addPhase_SetWalkDestinationByRobot(self, x, y, theta):

        self.addPhase("Set the walk destination")
        self.addCommand("Destination marker") \
            .setDefault() \
            .setFunction(lambda proc : self.setWalkDestinationByRobot(proc, x, y, theta)) \
            .linkToNextCommand()
        self.addCommand("Execute the walk") \
            .setFunction(self.executeWalkAndWaitForHeightFieldUpdated) \
            .linkToNextPhase()

    def executeWalkAndWaitForHeightFieldUpdated(self, proc):
        if self.ui.executeFootSteps():
            proc.waitForSignal(self.ui.sigHeightFieldUpdated())

cnoid.Base.TaskView.instance().updateTask(CISampleTask(DRCUserInterfaceItem.instance()))
