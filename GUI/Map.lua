local addon, ns = ...

LOP_MAP_PLAYER_SIZE = 12;

LOPMapMixin = {};


function LOPMapMixin:AddStandardDataProviders()
    self:AddDataProvider(CreateFromMixins(MapExplorationDataProviderMixin));

    self.groupMembersDataProvider = CreateFromMixins(GroupMembersDataProviderMixin);
    self.groupMembersDataProvider:SetUnitPinSize("player", LOP_MAP_PLAYER_SIZE);
    self:AddDataProvider(self.groupMembersDataProvider);

    local pinFrameLevelsManager = self:GetPinFrameLevelsManager();
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_MAP_EXPLORATION");
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_GROUP_MEMBER");
end

function LOPMapMixin:OnLoad()
    MapCanvasMixin.OnLoad(self);
    self:SetShouldZoomInOnClick(false);
    self:SetShouldPanOnClick(false);
    self:SetShouldNavigateOnClick(false);
    self:AddStandardDataProviders();
end
