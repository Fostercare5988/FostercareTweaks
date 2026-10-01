"""Headless Lua 5.1 UI/state regressions; rendering still needs WoW testing.
Run: python -B tests/test_frames.py [directory-containing-lupa]
"""
from pathlib import Path
import sys
import unittest
if len(sys.argv)>1 and Path(sys.argv[1]).is_dir(): sys.path.insert(0,sys.argv.pop(1))
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

STUBS=r'''
now=100; shift=false; ctrl=false; frames={}; timers={}; auras={}; cancelled={}
STANDARD_TEXT_FONT="test"; UISpecialFrames={}; CANCEL="Cancel"; CLOSE="Close"; OKAY="Okay"; DEFAULTS="Defaults"
floor=math.floor; wipe=function(t) for k in pairs(t) do t[k]=nil end end
table.wipe=wipe
local methods={}
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:SetParent(p) self.parent=p end
function methods:SetScript(k,f) self.scripts[k]=f end
function methods:GetScript(k) return self.scripts[k] end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false; if self.scripts.OnHide then fire(self,"OnHide") end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetLeft() return self.left end
function methods:GetRight() return self.left+self.width end
function methods:GetTop() return self.top end
function methods:ClearAllPoints() self.point=nil end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(self.point or {"TOPLEFT",UIParent,"TOPLEFT",0,0}) end
function methods:GetFrameLevel() return 1 end
function methods:SetTexture(...) self.texture={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:GetVertexColor() return unpack(self.color or {1,1,1,1}) end
function methods:SetStatusBarColor(...) self.statusBarColor={...} end
function methods:GetStatusBarColor() return unpack(self.statusBarColor or {0,1,0,1}) end
function methods:SetTextColor(...) self.textColor={...} end
function methods:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
function methods:SetSequence(v) self.sequence=v; self.sequenceCalls=(self.sequenceCalls or 0)+1 end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function methods:SetTexCoord(...) self.texcoords={...} end
function methods:SetID(v) self.id=v end
function methods:GetID() return self.id or 0 end
function methods:SetText(v) self.textValue=v end
function methods:GetText() return self.textValue end
function methods:Enable() self.disabled=false end
function methods:Disable() self.disabled=true end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetValue(v) self.value=v; if self.scripts.OnValueChanged then fire(self,"OnValueChanged") end end
function methods:GetValue() return self.value or 0 end
function methods:SetMinMaxValues(a,b) self.minimum=a; self.maximum=b end
function methods:GetMinMaxValues() return self.minimum or 0,self.maximum or 100 end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:EnableMouse(v) self.mouse=v end
function methods:GetFontString() if not self.font then self.font=CreateFrame("Font",nil,self) end; return self.font end
function methods:CreateTexture(n) return CreateFrame("Texture",n,self) end
function methods:CreateFontString(n) return CreateFrame("Font",n,self) end
function methods:SetFont(font, size, flags) self.fontFile=font; self.fontSize=size; self.fontFlags=flags end
function methods:GetFont() return self.fontFile or "Fonts\\FRIZQT__.TTF", self.fontSize or 10, self.fontFlags or "OUTLINE" end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha or 1 end
function CreateFrame(kind,name,parent,template)
 local f={name=name,parent=parent,shown=true,width=64,height=34,scale=1,left=0,top=600,scripts={},events={}}
 setmetatable(f,{__index=function(t,k)
  -- 1.12 sliders are frames, not buttons: they have no Enable/Disable methods.
  if k=="Enable" or k=="Disable" then
   if kind=="Button" or kind=="CheckButton" then return methods[k] end
   return nil
  end
  if methods[k] then return methods[k] end
  if string.match(k,"^[A-Z]") then return function() end end
 end})
 if name then _G[name]=f end
 if template then
  for _,s in ipairs({"Text","Low","High"}) do if name then _G[name..s]=CreateFrame("Font",nil,f) end end
 end
 table.insert(frames,f); return f
end
function fire(f,script,ev,a1,a2)
 local prev=this; this=f; event=ev; arg1=a1; arg2=a2
 f.scripts[script](); this=prev
end
UIParent=CreateFrame("Frame","UIParent"); UIParent.height=900
WorldFrame=CreateFrame("Frame","WorldFrame")
PlayerFrame=CreateFrame("Button","PlayerFrame",UIParent)
TargetFrame=CreateFrame("Button","TargetFrame",UIParent)
TargetofTargetFrame=CreateFrame("Button","TargetofTargetFrame",UIParent)
ComboFrame=CreateFrame("Frame","ComboFrame",UIParent)
GameTooltip=CreateFrame("Frame","GameTooltip",UIParent)
function GameTooltip:SetUnitAura(unit,index,filter) self.lastAura={unit,index,filter} end
function GetTime() return now end
function IsShiftKeyDown() return shift end
function IsControlKeyDown() return ctrl end
function IsLeftShiftKeyDown() if leftShift~=nil then return leftShift end; return shift end
function IsRightShiftKeyDown() return rightShift end
function IsLeftControlKeyDown() if leftCtrl~=nil then return leftCtrl end; return ctrl end
function IsRightControlKeyDown() return rightCtrl end
function UnitExists(u) return u~=nil end
unitGUIDs={}
function UnitGUID(u) if not u then return nil end; return unitGUIDs[u] or "GUID:"..u end
function UnitIsUnit(a,b) return a and b and UnitGUID(a)==UnitGUID(b) end
function UnitName(u) return u end
function UnitHealth() return 3000 end
function UnitHealthMax() return 4000 end
function UnitMana() return 2000 end
function UnitManaMax() return 3000 end
function UnitPowerType() return 0 end
function UnitClass() return "Priest","PRIEST" end
function UnitIsDeadOrGhost() return false end
function UnitIsGhost() return false end
function UnitIsConnected() return true end
function UnitIsPartyLeader() return false end
function UnitAffectingCombat(u) return inCombat or false end
function IsResting() return resting or false end
function UnitInRange() return true end
function UnitIsPlayer() return true end
function UnitPlayerControlled() return true end
function GetRaidTargetIndex(u) return (raidTargets and raidTargets[u]) or nil end
function UnitThreatSituation() return 0 end
function GetNumRaidMembers() return raidCount or 0 end
function GetNumPartyMembers() return partyCount or 0 end
function GetRaidRosterInfo(i) return "Player"..i,0,math.ceil(i/5),60,"Priest","PRIEST","Zone",true,false end
function SetRaidTargetIconTexture(texture, idx)
    if not texture then return end
    texture.raidIndex = idx
    if not idx or idx < 1 or idx > 8 then return end
    local i = idx - 1
    local l = (i % 4) * 0.25
    local r = l + 0.25
    local t = math.floor(i / 4) * 0.25
    local b = t + 0.25
    texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    texture:SetTexCoord(l, r, t, b)
end
function UnitLevel(u) return (unitLevels and unitLevels[u]) or 60 end
function SetPortraitTexture() end
function UnitClassification(u) return (unitClassifications and unitClassifications[u]) or "normal" end
function UnitFactionGroup(u) return (unitFaction and unitFaction[u]) or "Alliance" end
function UnitIsPVP(u) return (unitPVP and unitPVP[u]) or false end
function UnitIsPVPFreeForAll(u) return (unitFFA and unitFFA[u]) or false end
function GetDifficultyColor(lvl) if difficultyColors and difficultyColors[lvl] then return difficultyColors[lvl] end; return {r=1,g=1,b=0} end
function UnitCreatureType() return "Humanoid" end
function UnitReaction() return 4 end
function UnitCanAttack() return true end
function GetComboPoints() return comboPoints or 0 end
function SetMouseoverUnit(u) mouseover=u end
function TargetUnit(u) clickedUnit=u end
function SpellIsTargeting() return false end
function GetScreenWidth() return 1200 end
function GetScreenHeight() return 900 end
function ReloadUI() reloads=(reloads or 0)+1 end
function CooldownFrame_SetTimer(f,start,duration,enabled)
 f.timer={start,duration,enabled}; f.timerCalls=(f.timerCalls or 0)+1
 if start>0 and duration>0 and enabled>0 then
  f.start=start; f.duration=duration; f.stopping=0; f:SetSequence(0); f:Show()
 else f:Hide() end
end
C_Timer={NewTicker=function(delay,cb) local h={delay=delay,callback=cb}; table.insert(timers,h); return h end}
C_Spell={CancelSpellByID=function(id) table.insert(cancelled,id) end}
C_UnitAuras={}
function C_UnitAuras.UnitBuff(unit,i,filter) auraReads=(auraReads or 0)+1; local t=auras[unit] and auras[unit].buffs; if t and t[i] then return unpack(t[i]) end end
function C_UnitAuras.UnitDebuff(unit,i,filter) auraReads=(auraReads or 0)+1; local t=auras[unit] and auras[unit].debuffs; if t and t[i] then return unpack(t[i]) end end
FostercareTweaks_Config={overwrites={}}
FostercareTweaks={mods={},overwrites={},T=setmetatable({},{__index=function(t,k) return k end})}
slotReads={}; slotQueries={}
function C_UnitAuras.GetAuraSlots(unit,filter,maxSlots,token,slots)
 assert(filter=="HELPFUL" and token==nil and type(slots)=="table")
 local buffs=auras[unit] and auras[unit].buffs or {}
 local n=math.min(#buffs,(maxSlots and maxSlots>0) and maxSlots or #buffs)
 for i=1,slots.n or 0 do slots[i]=nil end
 for i=1,n do slots[i]=100+i end
 slots.n=n
 table.insert(slotQueries,{unit,filter,maxSlots})
 return n<#buffs and "more" or nil,n
end
function C_UnitAuras.UnitAuraBySlot(unit,slot)
 table.insert(slotReads,{unit,slot})
 local buffs=auras[unit] and auras[unit].buffs
 if buffs and buffs[slot-100] then return unpack(buffs[slot-100]) end
end
function FostercareTweaks:register(m) self.mods[m.title]=m; return m end
function FostercareTweaks.Abbreviate(v) return tostring(v) end
function FostercareTweaks.HasUnitXP() return false end
function FostercareTweaks.AddBorder(button,inset)
 if not rawget(button, "FostercareTweaks_border") then button.FostercareTweaks_border=CreateFrame("Frame",nil,button) end
 return button.FostercareTweaks_border
end
function FostercareTweaks.HookScript() end
-- Only real globals can be hooked, as in Helpers.lua. Model the native
-- updater showing its aura buttons again, including through target-of-target.
for i=1,5 do CreateFrame("Button","TargetFrameBuff"..i,TargetFrame):Hide() end
for i=1,16 do CreateFrame("Button","TargetFrameDebuff"..i,TargetFrame):Hide() end
function TargetDebuffButton_Update()
 nativeTargetRefreshes=(nativeTargetRefreshes or 0)+1
 for _,kind in ipairs({"Buff","Debuff"}) do
  local list=auras.target and auras.target[kind=="Buff" and "buffs" or "debuffs"] or {}
  for i=1,(kind=="Buff" and 5 or 16) do
   local b=_G["TargetFrame"..kind..i]
   if list[i] then b:Show() else b:Hide() end
  end
 end
end
function FostercareTweaks.hooksecurefunc(name,callback)
 local orig=_G[name]; if type(orig)~="function" then return end
 _G[name]=function() orig(); callback() end
end
function aura(name,id,expiration,source)
 return {name,"icon"..id,2,"Magic",30,expiration or 0,source or "raid1",false,false,id,false,false,true}
end
function visible(t) local n=0; for _,b in ipairs(t) do if b:IsShown() then n=n+1 end end; return n end
'''

def runtime():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    for name in ('move-unitframes','unitframes/core','unitframes/auras','unitframes/player','unitframes/target','unitframes/tot','unitframes/raid'):
        lua.execute((ROOT/'mods'/f'{name}.lua').read_text(encoding='utf-8'))
    return lua


def native_runtime():
    lua=runtime()
    lua.execute(r"""
        BuffFrame=CreateFrame("Frame","BuffFrame",UIParent)
        TemporaryEnchantFrame=CreateFrame("Frame","TemporaryEnchantFrame",UIParent)
        for i=0,23 do
            local b=CreateFrame("Button","BuffButton"..i,BuffFrame)
            b.buffFilter=i<16 and "HELPFUL" or "HARMFUL"
            CreateFrame("Texture",b:GetName().."Icon",b)
            if b.buffFilter=="HARMFUL" then CreateFrame("Texture",b:GetName().."Border",b) end
            b:SetScript("OnClick",function() nativeClicks=(nativeClicks or 0)+1 end)
            CreateFrame("FontString",b:GetName().."Duration",BuffFrame)
        end
        for i=1,2 do
            CreateFrame("Button","TempEnchant"..i,TemporaryEnchantFrame)
            CreateFrame("FontString","TempEnchant"..i.."Duration",TemporaryEnchantFrame)
            CreateFrame("Texture","TempEnchant"..i.."Icon",_G["TempEnchant"..i])
            CreateFrame("Texture","TempEnchant"..i.."Border",_G["TempEnchant"..i])
        end
        function BuffButton_Update()
            this:Show(); _G[this:GetName().."Duration"]:Show()
            buffUpdates=(buffUpdates or 0)+1
        end
        qualities={[16]=4,[17]=3}; enchantSlots={16,17}; qualityReads=0
        function GetInventoryItemQuality(unit,slot) assert(unit=="player"); qualityReads=qualityReads+1; return qualities[slot] end
        function GetItemQualityColor(q) return q/10,0.2,0.3 end
        function BuffFrame_Enchant_OnUpdate()
            TempEnchant1:SetID(enchantSlots[1]); TempEnchant2:SetID(enchantSlots[2])
            TempEnchant1:Show(); TempEnchant2:Hide()
            TempEnchant1Duration:Show(); TempEnchant2Duration:Hide()
            BuffFrame:SetPoint("TOPRIGHT",TemporaryEnchantFrame,"TOPLEFT",-5,0)
        end
        function BuffButtons_UpdatePositions()
            BuffButton8:SetPoint("TOP",TempEnchant1,"BOTTOM",0,-15)
            BuffButton16:SetPoint("TOPRIGHT",TemporaryEnchantFrame,"TOPRIGHT",0,-90)
        end
        function FostercareTweaks.hooksecurefunc(name,callback)
            local previous=_G[name]
            _G[name]=function() previous(); callback() end
        end
    """)
    lua.execute((ROOT/'mods/standard-player-auras.lua').read_text(encoding='utf-8'))
    return lua

class FrameTests(unittest.TestCase):
    def test_all_lua_syntax(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        compile_=lua.eval('function(s,n) local f,e=loadstring(s,n); assert(f,e) end')
        for p in ROOT.rglob('*.lua'): compile_(p.read_text(encoding='utf-8-sig'),str(p))

    def test_standard_player_has_multiple_buffs_and_debuffs(self):
        lua=runtime(); lua.execute('''auras.player={buffs={aura("A",1),aura("B",2),aura("C",3)},debuffs={aura("D",4)}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzPlayerAuras()
        local c=FostercareTweaks.UnitFrames.blizzPlayerAuras
        assert(visible(c.buffButtons)==3 and visible(c.debuffButtons)==1)
        assert(PlayerFrame:IsShown() and c:IsShown())''')

    def test_unknown_expiration_does_not_create_a_timer(self):
        lua=runtime(); lua.execute('''auras.target={buffs={aura("A",1,0)}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local b=FostercareTweaks.UnitFrames.blizzTargetAuras.buffButtons[1]
        assert(b:IsShown() and b.expirationTime==0 and not b.cooldown:IsShown())
        now=110; A:UpdateBlizzTargetAuras(); assert(b.expirationTime==0)''')

    def test_filtered_debuff_uses_plain_tooltip_index(self):
        lua=runtime(); lua.execute('''FostercareTweaks_Config["Only Show My Debuffs on Target"]=1
        auras.target={debuffs={aura("Other",1,0,"raid1"),aura("Mine",2,130,"player"),aura("Pet",3,130,"pet")}}
        FostercareTweaks.UnitFrames.Auras:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        assert(visible(c.debuffButtons)==2)
        fire(c.debuffButtons[1],"OnEnter"); assert(GameTooltip.lastAura[2]==2)
        fire(c.debuffButtons[2],"OnEnter"); assert(GameTooltip.lastAura[2]==3)''')

    def test_cancel_uses_spell_identity_after_slot_compaction(self):
        lua=runtime(); lua.execute('''auras.player={buffs={aura("A",10),aura("B",20)}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzPlayerAuras()
        local b=FostercareTweaks.UnitFrames.blizzPlayerAuras.buffButtons[2]
        auras.player.buffs={aura("B",20)}
        fire(b,"OnClick",nil,"RightButton"); assert(cancelled[1]==20)''')

    def test_standard_target_mirrors_rows_and_wraps_after_eight(self):
        lua=runtime(); lua.execute('''TargetFrame:SetWidth(232); TargetFrame:SetHeight(100)
        auras.target={buffs={},debuffs={}}
        local A=FostercareTweaks.UnitFrames.Auras
        for _,count in ipairs({6,8,9}) do
            auras.target.buffs={}; auras.target.debuffs={}
            for i=1,count do
                auras.target.buffs[i]=aura("B",i)
                auras.target.debuffs[i]=aura("D",100+i)
            end
            A:UpdateBlizzTargetAuras()
            local c=FostercareTweaks.UnitFrames.blizzTargetAuras
            for _,kind in ipairs({"buff","debuff"}) do
                local row=c[kind.."Frame"]; local buttons=c[kind.."Buttons"]
                assert(row:GetWidth()==math.min(count,8)*23-3)
                assert(row:GetHeight()==(count>8 and 43 or 20))
                assert(buttons[1].point[1]=="TOPRIGHT" and buttons[1].point[4]==0)
                assert(buttons[6].point[4]==-115 and buttons[6].point[5]==0)
                if count==9 then assert(buttons[9].point[4]==0 and buttons[9].point[5]==-23) end
                fire(buttons[6],"OnEnter"); assert(GameTooltip.lastAura[2]==6)
            end
            assert(c.buffFrame.point[1]=="TOPRIGHT" and c.buffFrame.point[3]=="BOTTOMRIGHT")
            assert(c.buffFrame.point[4]==-5 and c.buffFrame.point[5]==-34)
            assert(c.debuffFrame.point[2]==c.buffFrame and c.debuffFrame.point[3]=="BOTTOMRIGHT")
        end
        auras.player={buffs=auras.target.buffs}; A:UpdateBlizzPlayerAuras()
        local player=FostercareTweaks.UnitFrames.blizzPlayerAuras
        assert(player.buffButtons[6].point[1]=="TOPLEFT" and player.buffButtons[6].point[4]==115)
        assert(player.buffFrame.point[1]=="TOPLEFT")''')

    def test_target_saved_left_anchor_converts_once_and_keeps_right_edge(self):
        lua=runtime(); lua.execute('''FostercareTweaks_Config.unitframe_positions={
            standard_target_buffs={point="TOPLEFT",relPoint="TOPLEFT",x=70,y=60},
            standard_target_debuffs={point="TOPLEFT",relPoint="TOPLEFT",x=90,y=-100},
            standard_player_buffs={point="TOPLEFT",relPoint="TOPLEFT",x=40,y=60}}
        auras.target={buffs={aura("B",1),aura("B",2)},debuffs={aura("D",3)}}
        auras.player={buffs={aura("B",1)}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras(); A:UpdateBlizzPlayerAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        local positions=FostercareTweaks_Config.unitframe_positions
        assert(positions.standard_target_buffs.point=="TOPRIGHT" and positions.standard_target_buffs.x==113)
        assert(positions.standard_target_debuffs.point=="TOPRIGHT" and positions.standard_target_debuffs.x==110)
        assert(positions.standard_target_buffs.y==60 and positions.standard_target_debuffs.y==-100)
        assert(positions.standard_player_buffs.point=="TOPLEFT" and positions.standard_player_buffs.x==40)
        A:ApplyBuffSize(c,30); A:ApplyDebuffSize(c,32)
        for i=3,12 do auras.target.buffs[i]=aura("B",i) end
        A:UpdateBlizzTargetAuras()
        assert(c.buffFrame.point[4]==113 and c.debuffFrame.point[4]==110)
        -- Recreate containers as on reload; already converted anchors must not drift.
        FostercareTweaks.UnitFrames.blizzTargetAuras=nil; A:UpdateBlizzTargetAuras()
        local restored=FostercareTweaks.UnitFrames.blizzTargetAuras
        assert(restored.buffFrame.point[1]=="TOPRIGHT" and restored.buffFrame.point[4]==113)
        assert(restored.debuffFrame.point[1]=="TOPRIGHT" and restored.debuffFrame.point[4]==110)''')

    def test_modern_aura_growth_remains_left_aligned_after_resize(self):
        lua=runtime(); lua.execute('''auras.target={buffs={},debuffs={}}
        for i=1,9 do auras.target.buffs[i]=aura("B",i); auras.target.debuffs[i]=aura("D",100+i) end
        local A=FostercareTweaks.UnitFrames.Auras
        local c=A:CreateAuraContainer(TargetFrame,"target",32,48,{perRow=8,buffAnchor="TOP",debuffAnchor="BOTTOM"})
        A:ApplyBuffSize(c,30); A:ApplyDebuffSize(c,32); A:UpdateContainer(c)
        assert(c.buffButtons[6].point[1]=="BOTTOMLEFT" and c.buffButtons[6].point[4]==165)
        assert(c.buffButtons[9].point[4]==0 and c.buffButtons[9].point[5]==33)
        assert(c.debuffButtons[6].point[1]=="TOPLEFT" and c.debuffButtons[6].point[4]==175)
        assert(c.debuffButtons[9].point[5]==-35)''')

    def test_aura_position_survives_refresh_and_resize(self):
        lua=runtime(); lua.execute('''FostercareTweaks_Config.unitframe_positions={standard_target_buffs={point="TOPLEFT",relPoint="TOPLEFT",x=70,y=-90}}
        auras.target={buffs={aura("A",1),aura("B",2)}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        A:ApplyBuffSize(c,30); A:UpdateBlizzTargetAuras()
        assert(c.buffFrame.point[1]=="TOPRIGHT" and c.buffFrame.point[4]==113 and c.buffFrame.point[5]==-90)''')

    def test_aura_row_bounds_and_debuff_layout_cover_multiple_rows(self):
        lua=runtime(); lua.execute('''auras.target={buffs={},debuffs={aura("D",50)}}
        for i=1,12 do auras.target.buffs[i]=aura("B",i) end
        FostercareTweaks.UnitFrames.Auras:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        assert(c.buffFrame:GetHeight()==43)
        assert(c.debuffFrame.point[2]==c.buffFrame and c.debuffFrame.point[3]=="BOTTOMRIGHT")''')

    def test_modifier_events_use_current_classicapi_state_before_native_state(self):
        for shift_side in ("leftShift","rightShift"):
            for ctrl_side in ("leftCtrl","rightCtrl"):
                for order in ((shift_side,ctrl_side),(ctrl_side,shift_side)):
                    with self.subTest(shift=shift_side,ctrl=ctrl_side,order=order):
                        lua=runtime(); lua.execute('''leftShift=false; rightShift=false; leftCtrl=false; rightCtrl=false
                        FostercareTweaks.mods["Movable Unit Frames"].enable()
                        assert(not FCTweaksGridFrame:IsShown())''')
                        lua.globals()[order[0]]=True
                        lua.execute('fire(FCTweaksUnitFrameUnlocker,"OnEvent","MODIFIER_STATE_CHANGED")')
                        lua.execute('assert(not FCTweaksGridFrame:IsShown())')
                        lua.globals()[order[1]]=True
                        lua.execute('''-- Native merged state is still false during the message-hook event.
                        assert(not IsShiftKeyDown() and not IsControlKeyDown())
                        fire(FCTweaksUnitFrameUnlocker,"OnEvent","MODIFIER_STATE_CHANGED")
                        assert(FCTweaksGridFrame:IsShown() and PlayerFrame.fctMover:IsShown())
                        fire(PlayerFrame.fctMover,"OnDragStart"); assert(PlayerFrame.moving)
                        shift=true; ctrl=true''')
                        lua.globals()[order[1]]=False
                        lua.execute('''-- The native merged query still says held during the release event.
                        fire(FCTweaksUnitFrameUnlocker,"OnEvent","MODIFIER_STATE_CHANGED")
                        assert(not FCTweaksGridFrame:IsShown() and not PlayerFrame.fctMover:IsShown())
                        assert(not PlayerFrame.moving)''')

    def test_modifier_release_keeps_other_side_held_and_live_movement_toggle(self):
        lua=runtime(); lua.execute('''FostercareTweaks_Config["Movable Unit Frames"]=0
        FostercareTweaks.UnitFrames:ApplyConfiguration()
        assert(FCTweaksGridFrame==nil)
        ''')
        lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
        lua.execute('''FostercareTweaksSettingsGUI.SelectTab(2)
        ctrl=true; shift=true
        FCTweaksMoveUFCB:SetChecked(true); fire(FCTweaksMoveUFCB,"OnClick")
        assert(FCTweaksGridFrame and FCTweaksGridFrame:IsShown())
        leftShift=true; rightShift=true; leftCtrl=true; rightCtrl=false
        fire(FCTweaksUnitFrameUnlocker,"OnEvent","MODIFIER_STATE_CHANGED")
        leftShift=false; fire(FCTweaksUnitFrameUnlocker,"OnEvent","MODIFIER_STATE_CHANGED")
        assert(FCTweaksGridFrame:IsShown())
        local m=PlayerFrame.fctMover; fire(m,"OnDragStart")
        local anchor=PlayerFrame.point
        FostercareTweaks.mods["Movable Unit Frames"].enable()
        assert(PlayerFrame.point==anchor and PlayerFrame.moving)
        FCTweaksMoveUFCB:SetChecked(false); fire(FCTweaksMoveUFCB,"OnClick")
        assert(not FCTweaksGridFrame:IsShown() and not m:IsShown() and not PlayerFrame.moving)
        FCTweaksMoveUFCB:SetChecked(true); fire(FCTweaksMoveUFCB,"OnClick")
        assert(FCTweaksGridFrame:IsShown())
        rightShift=false; fire(FCTweaksUnitFrameUnlocker,"OnEvent","MODIFIER_STATE_CHANGED")
        assert(not FCTweaksGridFrame:IsShown())''')

    def test_modifier_release_stops_and_saves_only_dragged_owner(self):
        lua=runtime(); lua.execute('''FostercareTweaks.mods["Movable Unit Frames"].enable()
        shift=true; ctrl=true; FostercareTweaks.UpdateFrameMovers()
        local m=PlayerFrame.fctMover; assert(m:IsShown())
        PlayerFrame.left=75; PlayerFrame.top=500; PlayerFrame.scale=2
        PlayerFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",75,-100)
        fire(m,"OnDragStart"); assert(PlayerFrame.moving)
        ctrl=false; FostercareTweaks.UpdateFrameMovers()
        assert(not PlayerFrame.moving and not m:IsShown())
        assert(FostercareTweaks_Config.unitframe_positions.standard_player.x==75)
        assert(FostercareTweaks_Config.unitframe_positions.standard_target==nil)''')

    def test_first_aura_drag_survives_refresh_and_reflows_after_drop(self):
        for unit in ("player","target"):
            for kind in ("buff","debuff"):
                with self.subTest(unit=unit,kind=kind):
                    lua=runtime(); lua.globals().dragUnit=unit; lua.globals().dragKind=kind
                    lua.execute('''auras[dragUnit]={buffs={aura("B",1)},debuffs={aura("D",2)}}
                    local A=FostercareTweaks.UnitFrames.Auras
                    local update=dragUnit=="player" and A.UpdateBlizzPlayerAuras or A.UpdateBlizzTargetAuras
                    update(A)
                    local c=dragUnit=="player" and FostercareTweaks.UnitFrames.blizzPlayerAuras or FostercareTweaks.UnitFrames.blizzTargetAuras
                    local row=c[dragKind.."Frame"]; local mover=row.fctMover
                    ctrl=true; shift=true; FostercareTweaks.UpdateFrameMovers()
                    fire(mover,"OnDragStart"); assert(row.moving)
                    -- Model the root-relative anchor native StartMoving supplies.
                    row:SetPoint("TOPLEFT",UIParent,"TOPLEFT",100,-120)
                    row.left=100; row.top=480; row.scale=2
                    c:GetParent().left=40; c:GetParent().top=600
                    local anchor=row.point; local width,height=row:GetWidth(),row:GetHeight()
                    local a=auras[dragUnit][dragKind=="buff" and "buffs" or "debuffs"]
                    for i=2,12 do a[i]=aura("New",100+i) end
                    update(A)
                    assert(row.point==anchor and row:GetWidth()==width and row:GetHeight()==height)
                    assert(row.occupiedCount==12)
                    fire(mover,"OnDragStop")
                    assert(not row.moving and not mover.dragging)
                    local p=FostercareTweaks_Config.unitframe_positions["standard_"..dragUnit.."_"..dragKind.."s"]
                    local expectedX=dragUnit=="target" and (100+width-(40+c:GetParent():GetWidth())*.5) or 80
                    assert(p.x==expectedX and p.y==180)
                    assert(p.point==(dragUnit=="target" and "TOPRIGHT" or "TOPLEFT"))
                    assert(row.point[2]==c:GetParent() and row.point[4]==expectedX and row.point[5]==180)
                    assert(row:GetWidth()>width and row:GetHeight()>height)
                    local dropped=row.point; update(A); assert(row.point==dropped)
                    ''')

    def test_movers_preserve_native_click_scripts_and_do_not_reveal_inactive_frames(self):
        lua=runtime(); lua.execute('''local click=function() end; PlayerFrame:SetScript("OnClick",click)
        TargetFrame:Hide(); FostercareTweaks.mods["Movable Unit Frames"].enable()
        shift=true;ctrl=true;FostercareTweaks.UpdateFrameMovers()
        assert(PlayerFrame:GetScript("OnClick")==click)
        assert(not TargetFrame:IsShown())''')

    def test_raid_buff_rows_and_grid_bounds(self):
        lua=runtime(); lua.execute('''raidCount=40; auras.raid1={buffs={}}
        for i=1,8 do auras.raid1.buffs[i]=aura("B",i) end
        local UF=FostercareTweaks.UnitFrames; UF:EnableRaidFrames()
        local b=FCTweaksRaidUnitG1M1
        assert(visible(b.buffBadges)==4)
        assert(FCTweaksRaidFrame:GetHeight()==5*34+4*3+13+16)
        FostercareTweaks_Config.overwrites.raid_buff_count=8
        UF:ApplyGroupDimensions(120); UF:UpdateAllRaidFrames()
        assert(visible(b.buffBadges)==8)
        FostercareTweaks_Config["Show Raid Buffs"]=0
        UF:ApplyGroupDimensions();UF:UpdateAllRaidFrames()
        assert(visible(b.buffBadges)==0 and FCTweaksRaidFrame:GetHeight()==5*34+4*3+16)''')

    def test_raid_badges_keep_tooltip_identity_and_real_stack_counts(self):
        lua=runtime(); lua.execute('''raidCount=1
        auras.raid1={buffs={aura("B",10)},debuffs={aura("D",20)}}
        local UF=FostercareTweaks.UnitFrames; UF:EnableRaidFrames()
        local b=FCTweaksRaidUnitG1M1
        assert(b.buffBadges[1].unit=="raid1" and b.buffBadges[1].auraIndex==1)
        assert(b.buffBadges[1].countText:GetText()==2)
        fire(b.buffBadges[1],"OnEnter"); assert(GameTooltip.lastAura[1]=="raid1" and GameTooltip.lastAura[3]=="HELPFUL")
        fire(b.debuffBadges[1],"OnEnter"); assert(GameTooltip.lastAura[1]=="raid1" and GameTooltip.lastAura[3]=="HARMFUL")
        assert(b.debuffBadges[1].countText:GetText()==2)
        assert(mouseover=="raid1")
        fire(b.buffBadges[1],"OnClick",nil,"LeftButton"); assert(clickedUnit=="raid1")
        fire(b.buffBadges[1],"OnLeave"); assert(mouseover==nil)''')

    def test_raid_preview_shows_buffs_and_uses_configured_spacing(self):
        lua=runtime(); lua.execute('''local UF=FostercareTweaks.UnitFrames
        UF:ToggleRaidTest(); assert(visible(FCTweaksRaidUnitG1M1.buffBadges)==4)
        UF:ApplyGroupDimensions(100,40,1,12,8); UF:UpdateAllRaidFrames()
        assert(FCTweaksRaidFrame:GetWidth()==8*(100+12)-12)
        assert(visible(FCTweaksRaidUnitG1M1.buffBadges)==4)''')

    def test_shared_timer_clears_expired_text_without_faking_a_new_duration(self):
        lua=runtime(); lua.execute('''auras.player={buffs={aura("A",1,105)}}
        FostercareTweaks.UnitFrames.Auras:UpdateBlizzPlayerAuras()
        local b=FostercareTweaks.UnitFrames.blizzPlayerAuras.buffButtons[1]
        now=106; timers[1].callback()
        assert(not b.durationText:IsShown() and not b.cooldown:IsShown())
        assert(b:IsShown())''')

    def test_group_toggle_restores_native_party_event_ownership(self):
        lua=runtime(); lua.execute('''partyCount=2
        for i=1,4 do
            local f=CreateFrame("Button","PartyMemberFrame"..i,UIParent)
            f:RegisterEvent("UNIT_AURA")
        end
        local UF=FostercareTweaks.UnitFrames
        UF:ApplyGroupDimensions(nil,nil,nil,nil,nil,true)
        assert(not PartyMemberFrame1:IsShown() and PartyMemberFrame1.events.UNIT_AURA)
        UF:ApplyGroupDimensions(nil,nil,nil,nil,nil,false)
        assert(PartyMemberFrame1:IsShown() and PartyMemberFrame2:IsShown())
        assert(PartyMemberFrame1.events.UNIT_AURA and not FCTweaksRaidFrame:IsShown())
        UF:ApplyGroupDimensions(nil,nil,nil,nil,nil,true)
        assert(FCTweaksRaidFrame.events.UNIT_AURA and not PartyMemberFrame1:IsShown())''')

    def test_modern_frame_scale_does_not_resize_raid_grid(self):
        lua=runtime(); lua.execute('''local UF=FostercareTweaks.UnitFrames; UF:EnableRaidFrames()
        UF.raidFrame:SetScale(1.4); UF:ApplyScale(.75); assert(UF.raidFrame:GetScale()==1.4)''')

    def test_toc_load_graph_has_movers_before_frames(self):
        paths=[line.strip() for line in (ROOT/'FostercareTweaks.toc').read_text().splitlines()
               if line.strip() and not line.startswith('#')]
        for path in paths: self.assertTrue((ROOT/path.replace('\\','/')).is_file(),path)
        self.assertLess(paths.index('mods\\move-unitframes.lua'),paths.index('mods\\unitframes\\auras.lua'))
        self.assertLess(paths.index('mods\\move-unitframes.lua'),paths.index('mods\\standard-player-auras.lua'))

    def test_empty_buff_area_does_not_push_debuffs_down(self):
        lua=runtime(); lua.execute('''auras.target={debuffs={aura("D",1)}}
        FostercareTweaks.UnitFrames.Auras:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        assert(c.debuffFrame.point[2]==TargetFrame and c.debuffFrame.point[5]==-34)''')

    def test_setting_styles_are_mutually_exclusive(self):
        lua=runtime()
        lua.execute('FostercareTweaks.UnitFrames.ApplyConfiguration=function() end')
        lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
        lua.execute('''FostercareTweaksSettingsGUI.SelectTab(2)
        assert(FCTweaksStdPlayerCB:GetChecked() and not FCTweaksModPlayerCB:GetChecked())
        FCTweaksModPlayerCB:SetChecked(true); fire(FCTweaksModPlayerCB,"OnClick")
        assert(not FCTweaksStdPlayerCB:GetChecked() and FostercareTweaks_Config["Modern Player Frame"]==1)
        FCTweaksStdPlayerCB:SetChecked(true); fire(FCTweaksStdPlayerCB,"OnClick")
        assert(not FCTweaksModPlayerCB:GetChecked() and FostercareTweaks_Config["Modern Player Frame"]==0)
        assert(FostercareTweaksCancel:GetText()=="Close" and not FostercareTweaksOkay:IsShown())''')


    def test_standard_health_bar_class_colors_and_no_name_tint(self):
        lua=runtime()
        lua.execute(r'''MAX_PARTY_MEMBERS=4
            targetClass="ROGUE"; targetIsPlayer=true; targetExists=true
            targetReaction=4; targetTapped=false
            UnitClass=function(unit)
                if unit=="target" then return targetClass,targetClass end
                if unit=="party1" then return "Druid","DRUID" end
                return "Rogue","ROGUE"
            end
            UnitIsPlayer=function(unit) return unit~="target" or targetIsPlayer end
            UnitExists=function(unit) if unit=="target" then return targetExists end return true end
            UnitReaction=function(u,p) return targetReaction end
            UnitIsTapped=function(u) return targetTapped end
            UnitIsTappedByPlayer=function(u) return false end
            TargetFrameNameBackground=CreateFrame("Texture",nil,TargetFrame)
            TargetFrameHealthBar=CreateFrame("StatusBar","TargetFrameHealthBar",TargetFrame)
            TargetFrameHealthBar.unit="target"
            PlayerFrameHealthBar=CreateFrame("StatusBar","PlayerFrameHealthBar",PlayerFrame)
            PlayerFrameHealthBar.unit="player"
            PartyMemberFrame1HealthBar=CreateFrame("StatusBar","PartyMemberFrame1HealthBar",UIParent)
            PartyMemberFrame1HealthBar.unit="party1"
            PartyMemberFrame1Name=CreateFrame("Font",nil,UIParent)
            function TargetFrame_CheckFaction()
                TargetFrameNameBackground:Show()
                TargetFrameNameBackground:SetVertexColor(0,1,0,0.5)
            end
            function TargetFrame_Update()
                TargetFrame_CheckFaction()
            end
            function PlayerFrame_Update() end
            function PartyMemberFrame_UpdateMember() end
            function HealthBar_OnValueChanged(val) end
            TargetFrame_CheckFaction()
        ''')
        lua.execute('CLASSIC_API_VERSION=11515; SUPERWOW_VERSION=2; SlashCmdList={}; FostercareTweaks.mods={}')
        lua.execute((ROOT/'Core.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'mods/unitframes/core.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'mods/unitframes-classcolor.lua').read_text(encoding='utf-8'))
        lua.execute('''local m=FostercareTweaks.mods["Unit Frame Class Colors"]
            assert(m~=nil)
            FostercareTweaks:Initialize()
            m:enable()
            -- Player health bar is Rogue Yellow
            local pr, pg, pb = PlayerFrameHealthBar:GetStatusBarColor()
            assert(pr==1.00 and pb==0.41)
            -- Target health bar is Rogue Yellow
            local tr, tg, tb = TargetFrameHealthBar:GetStatusBarColor()
            assert(tr==1.00 and tb==0.41)
            -- Target name background is hidden (NO TINT!)
            assert(not TargetFrameNameBackground:IsShown())
            -- Player frame has no synthetic name background
            assert(PlayerFrameNameBackground==nil)
            -- Party 1 health bar and text are Druid Orange
            local dr, dg, db = PartyMemberFrame1HealthBar:GetStatusBarColor()
            assert(dr==1.00 and dg==0.49 and db==0.04)
            assert(PartyMemberFrame1Name.textColor[1]==1.00 and PartyMemberFrame1Name.textColor[2]==0.49)
            -- Target an NPC: reaction color is applied, NOT class color, and name background is hidden
            targetIsPlayer=false; targetReaction=2
            TargetFrame_Update()
            local hr, hg, hb = TargetFrameHealthBar:GetStatusBarColor()
            assert(hr==0.90 and hg==0.00)
            assert(not TargetFrameNameBackground:IsShown())
        ''')
        lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
        lua.execute('''FostercareTweaksSettingsGUI.SelectTab(2)
            assert(FCTweaksClassColorCB:GetChecked())
            FCTweaksClassColorCB:SetChecked(false); fire(FCTweaksClassColorCB,"OnClick")
            assert(FostercareTweaks_Config["Unit Frame Class Colors"]==0)
            local r, g, b = PlayerFrameHealthBar:GetStatusBarColor()
            assert(r==0 and g==1 and b==0)
            assert(TargetFrameNameBackground:IsShown())
            FCTweaksClassColorCB:SetChecked(true); fire(FCTweaksClassColorCB,"OnClick")
            assert(FostercareTweaks_Config["Unit Frame Class Colors"]==1)
            local r2, g2, b2 = PlayerFrameHealthBar:GetStatusBarColor()
            assert(r2==1.00 and b2==0.41)
            assert(not TargetFrameNameBackground:IsShown())
        ''')



    def test_eight_buffs_wrap_at_smallest_frame_with_largest_icons(self):
        lua=runtime(); lua.execute('''raidCount=5; auras.raid1={buffs={}}
        for i=1,12 do auras.raid1.buffs[i]=aura("B",i) end
        FostercareTweaks_Config.overwrites.raid_buff_count=8
        FostercareTweaks_Config.overwrites.raid_buff_size=18
        local UF=FostercareTweaks.UnitFrames; UF:ApplyGroupDimensions(40,20,1,0,0,true)
        local b=FCTweaksRaidUnitG1M1
        assert(visible(b.buffBadges)==8 and b.buffSpace==81)
        for i=1,8 do
            local badge=b.buffBadges[i]
            assert(badge.point[4]-1>=0 and badge.point[4]+badge:GetWidth()+1<=b:GetWidth())
            assert(-badge.point[5]+badge:GetHeight()+1<=b.buffSpace)
        end
        assert(b.buffBadges[3].point[4]==1 and b.buffBadges[3].point[5]==-22)
        assert(FCTweaksRaidUnitG1M2.point[5]==-117)
        assert(FCTweaksRaidFrame:GetHeight()==16+5*20+81)''')

    def test_resizing_reflows_buffs_without_losing_selection(self):
        lua=runtime(); lua.execute('''raidCount=5; auras.raid1={buffs={}}
        for i=1,8 do auras.raid1.buffs[i]=aura("B",i) end
        FostercareTweaks_Config.overwrites.raid_buff_count=8
        local UF=FostercareTweaks.UnitFrames; UF:ApplyGroupDimensions(120)
        local b=FCTweaksRaidUnitG1M1
        assert(visible(b.buffBadges)==8 and b.buffSpace==13)
        UF:ApplyGroupDimensions(40)
        assert(visible(b.buffBadges)==8 and b.buffSpace==37)
        assert(b.buffBadges[4].point[4]==1 and b.buffBadges[4].point[5]==-14)
        UF:ApplyGroupDimensions(120)
        assert(visible(b.buffBadges)==8 and b.buffSpace==13)
        assert(FostercareTweaks_Config.overwrites.raid_buff_count==8)''')

    def test_all_buffs_enumerates_client_slots_without_the_eight_icon_limit(self):
        lua=runtime(); lua.execute('''raidCount=1; auras.raid1={buffs={}}
        for i=1,32 do auras.raid1.buffs[i]=aura("B",i) end
        FostercareTweaks_Config["Show All Raid Buffs"]=1
        local UF=FostercareTweaks.UnitFrames; UF:ApplyGroupDimensions(40)
        local b=FCTweaksRaidUnitG1M1
        assert(visible(b.buffBadges)==32 and b.buffSpace==133)
        assert(b.buffBadges[32].spellId==32 and b.buffBadges[32].auraIndex==32)
        assert(b.buffBadges[32].countText:GetText()==2)
        assert(not b.buffBadges[32].cooldown:IsShown())
        assert(slotQueries[#slotQueries][3]==0 and slotReads[#slotReads][2]==132)
        fire(b.buffBadges[32],"OnEnter"); assert(GameTooltip.lastAura[2]==32)
        assert(mouseover=="raid1")
        fire(b.buffBadges[32],"OnClick",nil,"LeftButton"); assert(clickedUnit=="raid1")''')

    def test_aura_events_grow_and_shrink_occupied_rows(self):
        lua=runtime(); lua.execute('''raidCount=5; auras.raid1={buffs={aura("B",1)}}
        FostercareTweaks_Config["Show All Raid Buffs"]=1
        local UF=FostercareTweaks.UnitFrames; UF:ApplyGroupDimensions(40)
        local b=FCTweaksRaidUnitG1M1; local small=FCTweaksRaidFrame:GetHeight()
        for i=2,16 do auras.raid1.buffs[i]=aura("B",i) end
        fire(FCTweaksRaidFrame,"OnEvent","UNIT_AURA","raid1")
        assert(visible(b.buffBadges)==16 and b.buffSpace==73)
        assert(FCTweaksRaidFrame:GetHeight()==small+60)
        auras.raid1.buffs={aura("B",17)}
        fire(FCTweaksRaidFrame,"OnEvent","UNIT_AURA","raid1")
        assert(visible(b.buffBadges)==1 and b.buffSpace==13 and b.buffSlots.n==1)
        assert(b.buffSlots[2]==nil and b.buffBadges[16].unit==nil)
        assert(b.buffBadges[1].spellId==17 and FCTweaksRaidFrame:GetHeight()==small)
        auras.raid1.buffs={}; fire(FCTweaksRaidFrame,"OnEvent","UNIT_AURA","raid1")
        assert(b.buffSpace==0 and FCTweaksRaidFrame:GetHeight()==small-13)''')

    def test_all_mode_reserves_only_present_buffs_in_party_layout(self):
        lua=runtime(); lua.execute('''partyCount=2
        auras.player={buffs={aura("B",1)}}; auras.party1={buffs={}}
        for i=1,8 do auras.party1.buffs[i]=aura("B",i) end
        FostercareTweaks_Config["Show All Raid Buffs"]=1
        local UF=FostercareTweaks.UnitFrames; UF:ApplyGroupDimensions(40)
        assert(FCTweaksRaidUnitG1M1.buffSpace==13 and FCTweaksRaidUnitG1M2.buffSpace==37)
        assert(FCTweaksRaidFrame:GetWidth()==40)
        assert(FCTweaksRaidFrame:GetHeight()==16+3*34+2*3+13+37)
        assert(not FCTweaksRaidGroup2:IsShown())''')

    def test_each_group_uses_its_own_buff_rows_and_container_contains_the_tallest(self):
        lua=runtime(); lua.execute('''raidCount=10; auras.raid1={buffs={}}; auras.raid6={buffs={}}
        for i=1,16 do auras.raid1.buffs[i]=aura("B",i) end
        for i=1,4 do auras.raid6.buffs[i]=aura("B",i) end
        FostercareTweaks_Config["Show All Raid Buffs"]=1
        local UF=FostercareTweaks.UnitFrames; UF:ApplyGroupDimensions(40)
        assert(FCTweaksRaidGroup1:GetHeight()==16+5*34+4*3+73)
        assert(FCTweaksRaidGroup2:GetHeight()==16+5*34+4*3+25)
        assert(FCTweaksRaidFrame:GetHeight()==FCTweaksRaidGroup1:GetHeight())
        assert(FCTweaksRaidUnitG2M2.point[5]==-16-34-25-3)''')

    def test_all_buffs_checkbox_applies_live_and_remembers_limited_count(self):
        lua=runtime(); lua.execute('FostercareTweaks.UnitFrames.ApplyConfiguration=function() end')
        lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
        lua.execute('''raidCount=1; auras.raid1={buffs={}}
        for i=1,12 do auras.raid1.buffs[i]=aura("B",i) end
        FostercareTweaks.UnitFrames:EnableRaidFrames()
        FostercareTweaksSettingsGUI.SelectTab(3)
        FCTweaksRaidBuffCountSlider:SetValue(8)
        FCTweaksRaidAllBuffsCB:SetChecked(true); fire(FCTweaksRaidAllBuffsCB,"OnClick")
        assert(FostercareTweaks_Config["Show All Raid Buffs"]==1)
        assert(FCTweaksRaidBuffCountSlider.mouse==false and FCTweaksRaidBuffCountSlider:GetAlpha()<1 and visible(FCTweaksRaidUnitG1M1.buffBadges)==12)
        assert(FCTweaksRaidBuffCountSlider.label:GetText()=="Buffs Per Player: All")
        FostercareTweaksSettingsGUI.raidPage:RefreshValues()
        assert(FCTweaksRaidAllBuffsCB:GetChecked() and FCTweaksRaidBuffCountSlider.mouse==false)
        FCTweaksRaidAllBuffsCB:SetChecked(false); fire(FCTweaksRaidAllBuffsCB,"OnClick")
        assert(FCTweaksRaidBuffCountSlider.mouse==true and FCTweaksRaidBuffCountSlider:GetAlpha()==1)
        assert(FostercareTweaks_Config.overwrites.raid_buff_count==8 and visible(FCTweaksRaidUnitG1M1.buffBadges)==8)
        FCTweaksRaidPageResetBtn.scripts.OnClick()
        assert(FostercareTweaks_Config["Show All Raid Buffs"]==0 and FostercareTweaks_Config.overwrites.raid_buff_count==4)
        assert(FCTweaksRaidBuffCountSlider.label:GetText()=="Buffs Per Player: 4")''')

    def test_native_slider_mock_rejects_button_only_enable_methods(self):
        lua=runtime(); lua.execute('''local slider=CreateFrame("Slider")
        assert(slider.Enable==nil and slider.Disable==nil)
        local button=CreateFrame("Button"); button:Disable(); assert(button.disabled)
        button:Enable(); assert(not button.disabled)''')

    def test_settings_reopen_saved_raid_tab_in_both_buff_modes(self):
        for all_buffs in (0,1):
            with self.subTest(all_buffs=all_buffs):
                lua=runtime()
                lua.execute('FostercareTweaks.UnitFrames.ApplyConfiguration=function() end')
                lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
                lua.globals().savedAll=all_buffs
                lua.execute('''FostercareTweaks_Config["Show All Raid Buffs"]=savedAll
                FostercareTweaks_Config.overwrites.raid_buff_count=7
                local gui=FostercareTweaksSettingsGUI
                gui.currentTab=3; fire(gui,"OnShow")
                local slider=FCTweaksRaidBuffCountSlider
                assert(slider:GetValue()==7 and slider.mouse==(savedAll==0))
                assert(slider:GetAlpha()==(savedAll==1 and 0.45 or 1))
                assert(slider.label:GetText()=="Buffs Per Player: "..(savedAll==1 and "All" or "7"))
                gui.SelectTab(2); gui.SelectTab(3)
                gui:Hide(); fire(gui,"OnShow")
                assert(slider:GetValue()==7 and slider.mouse==(savedAll==0))
                fire(FCTweaksRaidPageResetBtn,"OnClick")
                assert(slider:GetValue()==4 and slider.mouse==true and slider:GetAlpha()==1)
                assert(FostercareTweaks_Config["Show All Raid Buffs"]==0)''')

    def test_disabling_buffs_hides_all_created_icons_and_removes_row_space(self):
        lua=runtime(); lua.execute('''raidCount=5; auras.raid1={buffs={}}
        for i=1,20 do auras.raid1.buffs[i]=aura("B",i) end
        FostercareTweaks_Config["Show All Raid Buffs"]=1
        local UF=FostercareTweaks.UnitFrames; UF:ApplyGroupDimensions(40)
        local b=FCTweaksRaidUnitG1M1
        assert(visible(b.buffBadges)==20)
        FostercareTweaks_Config["Show Raid Buffs"]=0; UF:UpdateAllRaidFrames()
        assert(visible(b.buffBadges)==0 and b.buffSpace==0)
        assert(FCTweaksRaidFrame:GetHeight()==16+5*34+4*3)
        FostercareTweaks_Config["Show Raid Buffs"]=1; UF:UpdateAllRaidFrames()
        assert(visible(b.buffBadges)==20 and b.buffSpace==85)''')

    def test_buff_icon_gaps_do_not_leave_stale_high_index_badges(self):
        lua=runtime(); lua.execute('''raidCount=1; auras.raid1={buffs={}}
        for i=1,12 do auras.raid1.buffs[i]=aura("B",i) end
        auras.raid1.buffs[9][2]=nil
        FostercareTweaks_Config["Show All Raid Buffs"]=1
        local UF=FostercareTweaks.UnitFrames; UF:EnableRaidFrames()
        local b=FCTweaksRaidUnitG1M1
        assert(visible(b.buffBadges)==11 and b.buffBadges[12]:IsShown())
        fire(b.buffBadges[10],"OnEnter"); assert(GameTooltip.lastAura[2]==10)
        auras.raid1.buffs={}; fire(FCTweaksRaidFrame,"OnEvent","UNIT_AURA","raid1")
        assert(visible(b.buffBadges)==0 and b.buffBadges[12].unit==nil)''')

    def test_all_buff_preview_matches_wrapping_and_live_dimension_changes(self):
        lua=runtime(); lua.execute('''FostercareTweaks_Config["Show All Raid Buffs"]=1
        local UF=FostercareTweaks.UnitFrames; UF:ToggleRaidTest()
        assert(visible(FCTweaksRaidUnitG1M1.buffBadges)==32)
        UF:ApplyGroupDimensions(40,20,1,0,0,true)
        assert(FCTweaksRaidFrame:GetHeight()==16+5*(20+133))
        assert(FCTweaksRaidUnitG1M2.point[5]==-16-20-133)
        UF:ApplyGroupDimensions(120,20,1,0,0,true)
        assert(visible(FCTweaksRaidUnitG1M1.buffBadges)==32)
        assert(FCTweaksRaidFrame:GetHeight()==16+5*(20+49))''')


    def test_native_areas_default_on_and_keep_original_scripts(self):
        lua=native_runtime(); lua.execute('''
        local oldClick=BuffButton0:GetScript("OnClick")
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        local a=FostercareTweaks.standardAuraAreas
        assert(#a[1].buttons==16 and #a[2].buttons==8 and #a[3].buttons==2)
        for _,area in ipairs(a) do assert(area.frame:IsShown()) end
        assert(BuffFrame:IsShown() and TemporaryEnchantFrame:IsShown())
        assert(BuffButton0:GetScript("OnClick")==oldClick)
        fire(BuffButton0,"OnClick"); assert(nativeClicks==1)
        assert(BuffButton16:GetParent()==a[2].frame and BuffButton0:GetParent()==a[1].frame)
        assert(TempEnchant1:GetParent()==a[3].frame and TempEnchant2:IsShown()==false)''')

    def test_native_areas_hide_independently_despite_native_refresh(self):
        lua=native_runtime(); lua.execute('''
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        local a=FostercareTweaks.standardAuraAreas
        FostercareTweaks_Config["Show Standard Buffs"]=0
        FostercareTweaks_Config["Show Weapon Enchants"]=0
        FostercareTweaks.ApplyStandardAuraSettings()
        assert(not BuffButton0:IsVisible() and BuffButton16:IsVisible() and not TempEnchant1:IsVisible())
        assert(BuffButton0Duration:GetAlpha()==0 and BuffButton16Duration:GetAlpha()==1 and TempEnchant1Duration:GetAlpha()==0)
        this=BuffButton0; BuffButton_Update(); this=nil; BuffFrame_Enchant_OnUpdate()
        assert(not BuffButton0:IsVisible() and BuffButton0Duration:GetAlpha()==0)
        FostercareTweaks_Config["Show Standard Buffs"]=1
        FostercareTweaks_Config["Show Standard Debuffs"]=0
        FostercareTweaks.ApplyStandardAuraSettings()
        assert(BuffButton0:IsVisible() and not BuffButton16:IsVisible())
        assert(BuffButton0Duration:GetAlpha()==1 and BuffButton16Duration:GetAlpha()==0)
        assert(FostercareTweaks_Config["Show Player Buffs"]==nil)
        assert(BuffFrame:IsVisible() and TemporaryEnchantFrame:IsVisible())''')

    def test_native_positions_survive_enchant_and_duration_anchor_updates(self):
        lua=native_runtime(); lua.execute('''
        FostercareTweaks_Config.unitframe_positions={standard_global_buffs={point="TOPLEFT",relPoint="TOPLEFT",x=120,y=-180}}
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        local a=FostercareTweaks.standardAuraAreas
        local point=a[1].frame.point
        SHOW_BUFF_DURATIONS="1"; BuffButtons_UpdatePositions(); BuffFrame_Enchant_OnUpdate()
        assert(a[1].frame.point==point and point[4]==120 and point[5]==-180)
        assert(BuffButton8.point[2]==a[1].frame and BuffButton8.point[5]==-45)
        assert(BuffButton16.point[2]==a[2].frame)
        SHOW_BUFF_DURATIONS="0"; BuffButtons_UpdatePositions()
        assert(BuffButton8.point[5]==-35 and a[1].frame.point==point)''')

    def test_native_movers_save_each_area_separately_and_respect_visibility(self):
        lua=native_runtime(); lua.execute('''
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        local a=FostercareTweaks.standardAuraAreas
        ctrl=true; shift=true; FostercareTweaks.UpdateFrameMovers()
        fire(a[2].frame.fctMover,"OnDragStart")
        assert(a[2].frame.moving and not a[1].frame.moving)
        a[2].frame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",100,-200)
        ctrl=false; FostercareTweaks.UpdateFrameMovers()
        assert(not a[2].frame.moving)
        local p=FostercareTweaks_Config.unitframe_positions
        assert(p.standard_global_debuffs.x==100 and p.standard_global_buffs==nil and p.standard_weapon_enchants==nil)
        FostercareTweaks_Config["Show Standard Debuffs"]=0; FostercareTweaks.ApplyStandardAuraSettings()
        ctrl=true; FostercareTweaks.UpdateFrameMovers()
        assert(not a[2].frame.fctMover:IsVisible() and a[1].frame.fctMover:IsVisible())''')

    def test_native_settings_apply_live_and_defaults_restore_all_three(self):
        lua=native_runtime(); lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
        lua.execute('''
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        FCTweaksUnitSettingsPage:RefreshValues()
        assert(FCTweaksNativeBuffsCB:GetChecked() and FCTweaksNativeDebuffsCB:GetChecked() and FCTweaksNativeEnchantsCB:GetChecked())
        FCTweaksNativeEnchantsCB:SetChecked(false); fire(FCTweaksNativeEnchantsCB,"OnClick")
        assert(FostercareTweaks_Config["Show Weapon Enchants"]==0 and not TempEnchant1:IsVisible())
        assert(FCTweaksNativeBuffsCB:GetChecked() and FCTweaksNativeDebuffsCB:GetChecked())
        fire(FCTweaksResetUFDefaultsBtn,"OnClick")
        assert(FostercareTweaks_Config["Show Weapon Enchants"]==1 and TempEnchant1:IsVisible())
        assert(FCTweaksNativeEnchantsCB:GetChecked())''')


    def test_native_module_enable_is_idempotent_and_preserves_script_context(self):
        lua=native_runtime(); lua.execute('''
        local previous=PlayerFrame; this=previous
        local m=FostercareTweaks.mods["Blizzard Aura Controls"]
        m:enable(); local a=FostercareTweaks.standardAuraAreas; m:enable()
        assert(FostercareTweaks.standardAuraAreas==a and #a==3 and this==previous)
        FostercareTweaks.ApplyStandardAuraSettings(); assert(this==previous)
        assert(a[1].frame.point[2]==BuffFrame and a[3].frame.point[2]==TemporaryEnchantFrame)''')

    def test_aura_border_toggles_are_independent_live_and_saved(self):
        lua=native_runtime(); lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
        lua.execute('''
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        FCTweaksUnitSettingsPage:RefreshValues()
        assert(not FCTweaksBuffBordersCB:GetChecked() and not FCTweaksDebuffBordersCB:GetChecked())
        assert(FCTweaksEnchantBordersCB:GetChecked() and TempEnchant1.fctAuraBorder:IsVisible())
        FCTweaksBuffBordersCB:SetChecked(true); fire(FCTweaksBuffBordersCB,"OnClick")
        assert(BuffButton0.fctAuraBorder:IsShown() and BuffButton16Border:GetAlpha()==0)
        assert(FostercareTweaks_Config["Show Buff Borders"]==1 and TempEnchant1:IsVisible())
        FCTweaksEnchantBordersCB:SetChecked(false); fire(FCTweaksEnchantBordersCB,"OnClick")
        FCTweaksDebuffBordersCB:SetChecked(true); fire(FCTweaksDebuffBordersCB,"OnClick")
        assert(not TempEnchant1.fctAuraBorder:IsShown() and BuffButton16Border:GetAlpha()==1)
        this=BuffButton16; BuffButton_Update(); this=nil
        assert(BuffButton16Border:GetAlpha()==1)
        assert(BuffButton0:IsVisible() and BuffButton16:IsVisible() and TempEnchant1:IsVisible())
        assert(not reloads)
        FostercareTweaksSettingsGUI.currentTab=2
        FostercareTweaksSettingsGUI:Hide(); fire(FostercareTweaksSettingsGUI,"OnShow")
        FCTweaksUnitSettingsPage:RefreshValues()
        assert(FCTweaksBuffBordersCB:GetChecked() and FCTweaksDebuffBordersCB:GetChecked() and not FCTweaksEnchantBordersCB:GetChecked())
        ''')
        # Recreate UI/runtime with the SavedVariables choices, as on login.
        saved={key:lua.globals().FostercareTweaks_Config[key] for key in
               ('Show Buff Borders','Show Debuff Borders','Show Weapon Enchant Borders')}
        reloaded=native_runtime()
        for key,value in saved.items(): reloaded.globals().FostercareTweaks_Config[key]=value
        reloaded.execute('''
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        assert(BuffButton0.fctAuraBorder:IsShown() and BuffButton16Border:GetAlpha()==1)
        assert(not TempEnchant1.fctAuraBorder and TempEnchant1:IsVisible())
        ''')

    def test_weapon_border_quality_refresh_does_not_poll_or_recreate(self):
        lua=native_runtime(); lua.execute('''
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        local border=TempEnchant1.fctAuraBorder
        assert(border.borderColor[1]==0.4 and border.mouse==false and TempEnchant1Border:GetAlpha()==0)
        local reads=qualityReads
        for i=1,100 do BuffFrame_Enchant_OnUpdate() end
        assert(qualityReads==reads and border==TempEnchant1.fctAuraBorder)
        enchantSlots={17,16}; BuffFrame_Enchant_OnUpdate()
        assert(border.borderColor[1]==0.3 and TempEnchant2.fctAuraBorder.borderColor[1]==0.4)
        qualities[17]=2
        for _,f in ipairs(frames) do
            if f.events.UNIT_INVENTORY_CHANGED then fire(f,"OnEvent","UNIT_INVENTORY_CHANGED","player") end
        end
        assert(border.borderColor[1]==0.2)
        FostercareTweaks_Config["Show Weapon Enchant Borders"]=0; FostercareTweaks.ApplyStandardAuraSettings()
        reads=qualityReads; BuffFrame_Enchant_OnUpdate(); assert(qualityReads==reads and not border:IsShown())
        qualities[17]=nil
        FostercareTweaks_Config["Show Weapon Enchant Borders"]=1; FostercareTweaks.ApplyStandardAuraSettings()
        assert(border:IsShown() and border.borderColor[1]==0.5 and border==TempEnchant1.fctAuraBorder)
        ''')

    def test_shared_and_raid_borders_refresh_without_changing_aura_identity(self):
        lua=runtime(); lua.execute('''
        auras.player={buffs={aura("A",1,130)},debuffs={aura("D",2,130)}}
        local UF=FostercareTweaks.UnitFrames; local A=UF.Auras
        A:UpdateBlizzPlayerAuras(); UF:ToggleRaidTest()
        local buff=UF.blizzPlayerAuras.buffButtons[1]; local debuff=UF.blizzPlayerAuras.debuffButtons[1]
        local raid=FCTweaksRaidUnitG1M2
        assert(not buff.border:IsShown() and not debuff.border:IsShown() and not raid.debuffBadges[1].border:IsShown())
        FostercareTweaks_Config["Show Buff Borders"]=1; A:RefreshBorders()
        assert(buff.border:IsShown() and raid.buffBadges[1].border:IsShown() and not debuff.border:IsShown())
        FostercareTweaks_Config["Show Debuff Borders"]=1; A:RefreshBorders()
        assert(debuff.border:IsShown() and debuff.border.color[3]==UF.DispelColors.Magic.b)
        assert(raid.debuffBadges[1].border:IsShown())
        assert(buff.spellId==1 and buff.expirationTime==130 and buff.cooldown:IsShown())
        fire(debuff,"OnEnter"); assert(GameTooltip.lastAura[2]==1 and GameTooltip.lastAura[3]=="HARMFUL")
        FostercareTweaks_Config["Show Buff Borders"]=0; A:UpdateBlizzPlayerAuras(); UF:UpdateAllRaidFrames()
        assert(not buff.border:IsShown() and not raid.buffBadges[1].border:IsShown() and debuff.border:IsShown())
        FostercareTweaks_Config["Color Debuffs by Dispel Type"]=0; A:UpdateBlizzPlayerAuras()
        assert(debuff.border:IsShown() and debuff.border.color[1]==0.15)
        ''')

    def test_aura_border_defaults_restore_without_resetting_visibility(self):
        lua=native_runtime(); lua.execute((ROOT/'Options.lua').read_text(encoding='utf-8'))
        lua.execute('''
        FostercareTweaks.mods["Blizzard Aura Controls"]:enable()
        FostercareTweaks_Config["Show Buff Borders"]=1; FostercareTweaks_Config["Show Debuff Borders"]=1
        FostercareTweaks_Config["Show Weapon Enchant Borders"]=0
        fire(FCTweaksResetUFDefaultsBtn,"OnClick")
        assert(FostercareTweaks_Config["Show Buff Borders"]==0 and FostercareTweaks_Config["Show Debuff Borders"]==0)
        assert(FostercareTweaks_Config["Show Weapon Enchant Borders"]==1 and TempEnchant1.fctAuraBorder:IsShown())
        assert(not BuffButton0.fctAuraBorder or not BuffButton0.fctAuraBorder:IsShown())
        assert(BuffButton16Border:GetAlpha()==0 and BuffButton0:IsVisible() and BuffButton16:IsVisible())
        ''')

    def test_native_target_refresh_cannot_reveal_duplicate_auras_or_rescan(self):
        lua=runtime(); lua.execute('''
        auras.target={buffs={aura("Buff",1,130)},debuffs={aura("Crippling",3409,130,"player")}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local poison=FostercareTweaks.UnitFrames.blizzTargetAuras.debuffButtons[1]
        local reads=auraReads; local calls=poison.cooldown.timerCalls
        for i=1,50 do TargetDebuffButton_Update() end
        assert(nativeTargetRefreshes==50 and not TargetFrameDebuff1:IsShown() and not TargetFrameBuff1:IsShown())
        assert(poison:IsVisible() and poison.spellId==3409)
        assert(auraReads==reads and poison.cooldown.timerCalls==calls)
        ''')

    def test_pvp_poison_application_refresh_and_dispel_update_on_event(self):
        lua=runtime(); lua.execute('''
        auras.target={debuffs={}}
        local UF=FostercareTweaks.UnitFrames; UF.Auras:UpdateBlizzTargetAuras()
        local b=UF.blizzTargetAuras.debuffButtons[1]; assert(not b:IsShown())
        auras.target.debuffs={aura("Crippling",3409,130,"player")}
        fire(FCTweaksAuraEventFrame,"OnEvent","UNIT_AURA","target")
        assert(b:IsShown() and b.spellId==3409 and b.expirationTime==130 and b.cooldown:IsShown())
        local calls=b.cooldown.timerCalls
        for i=1,20 do fire(FCTweaksAuraEventFrame,"OnEvent","UNIT_AURA","target") end
        assert(b.cooldown.timerCalls==calls)
        now=105; auras.target.debuffs[1][6]=135
        fire(FCTweaksAuraEventFrame,"OnEvent","UNIT_AURA","target")
        assert(b.expirationTime==135 and b.cooldown.timer[1]==105 and b.cooldown.timerCalls==calls+1)
        auras.target.debuffs={}; fire(FCTweaksAuraEventFrame,"OnEvent","UNIT_AURA","target")
        assert(not b:IsShown() and not b.cooldown:IsShown() and b.spellId==nil and b.durationText:GetText()=="")
        ''')

    def test_same_poison_does_not_inherit_cooldown_across_casters_or_targets(self):
        lua=runtime(); lua.execute('''
        auras.target={debuffs={aura("Crippling",3409,130,"player")}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local b=FostercareTweaks.UnitFrames.blizzTargetAuras.debuffButtons[1]
        local calls=b.cooldown.timerCalls
        auras.target.debuffs[1][7]="raid1"; A:UpdateBlizzTargetAuras()
        assert(b.cooldown.timerCalls==calls+1)
        unitGUIDs.target="GUID:newEnemy"; A:UpdateBlizzTargetAuras()
        assert(b.cooldown.timerCalls==calls+2)
        auras.target.debuffs[1][10]=11201; A:UpdateBlizzTargetAuras()
        assert(b.cooldown.timerCalls==calls+3 and b.spellId==11201)
        A:UpdateBlizzTargetAuras(); assert(b.cooldown.timerCalls==calls+3)
        ''')

    def test_poison_unknown_timing_stays_visible_and_sweep_toggle_applies(self):
        lua=runtime(); lua.execute('''
        auras.target={debuffs={aura("Crippling",3409,130,"player")}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local b=FostercareTweaks.UnitFrames.blizzTargetAuras.debuffButtons[1]
        FostercareTweaks_Config["Show Debuff Cooldown Spiral"]=0; A:UpdateBlizzTargetAuras()
        assert(not b.cooldown:IsShown() and b.durationText:IsShown())
        local calls=b.cooldown.timerCalls
        A:UpdateBlizzTargetAuras(); assert(b.cooldown.timerCalls==calls)
        FostercareTweaks_Config["Show Debuff Cooldown Spiral"]=1; A:UpdateBlizzTargetAuras()
        assert(b.cooldown:IsShown() and b.cooldown.timerCalls==calls+1)
        auras.target.debuffs[1][6]=0; A:UpdateBlizzTargetAuras()
        assert(b:IsVisible() and b.spellId==3409 and not b.cooldown:IsShown() and not b.durationText:IsShown())
        now=125; A:UpdateBlizzTargetAuras(); assert(b.expirationTime==0)
        ''')

    def test_target_aura_toggle_restores_native_buttons_without_recursing(self):
        lua=runtime(); lua.execute('''
        auras.target={debuffs={aura("Crippling",3409,130,"player")}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        FostercareTweaks_Config["Improved Standard Auras"]=0; A:UpdateBlizzTargetAuras()
        assert(TargetFrameDebuff1:IsShown() and not c:IsShown() and c.debuffButtons[1].spellId==nil)
        assert(not c.debuffButtons[1].cooldown:IsShown())
        FostercareTweaks_Config["Improved Standard Auras"]=1; A:UpdateBlizzTargetAuras()
        assert(c:IsShown() and c.debuffButtons[1]:IsVisible() and not TargetFrameDebuff1:IsShown())
        FostercareTweaks_Config["Modern Target Frame"]=1; TargetDebuffButton_Update()
        assert(not TargetFrameDebuff1:IsShown())
        ''')

    def test_target_loss_clears_bound_poison_and_timer(self):
        lua=runtime(); lua.execute('''
        auras.target={debuffs={aura("Crippling",3409,130,"player")}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras; local b=c.debuffButtons[1]
        TargetFrame:Hide(); fire(FCTweaksAuraEventFrame,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(not c:IsShown() and b.spellId==nil and b.timerUnitGUID==nil and not b.cooldown:IsShown())
        TargetFrame:Show(); auras.target.debuffs={aura("Crippling",3409,0,"player")}
        fire(FCTweaksAuraEventFrame,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(b:IsShown() and b.spellId==3409 and b.expirationTime==0 and not b.cooldown:IsShown())
        ''')

    def test_aura_event_aliases_refresh_current_unit_without_polling(self):
        lua=runtime(); lua.execute('''
        local timerCount=#timers
        unitGUIDs.target="GUID:enemy"; unitGUIDs.mouseover="GUID:enemy"
        auras.target={debuffs={}}
        FostercareTweaks.UnitFrames.Auras:UpdateBlizzTargetAuras()
        auras.target.debuffs={aura("Crippling",3409,130,"player")}
        fire(FCTweaksAuraEventFrame,"OnEvent","UNIT_AURA","mouseover")
        assert(FostercareTweaks.UnitFrames.blizzTargetAuras.debuffButtons[1].spellId==3409)
        local reads=auraReads
        fire(FCTweaksAuraEventFrame,"OnEvent","UNIT_AURA","raid1"); assert(auraReads==reads)
        -- A self-target aura event updates both presentations.
        unitGUIDs.target=UnitGUID("player")
        auras.player={buffs={aura("A",42)}}
        fire(FCTweaksAuraEventFrame,"OnEvent","UNIT_AURA","player")
        assert(FostercareTweaks.UnitFrames.blizzPlayerAuras.buffButtons[1].spellId==42)
        assert(#timers==timerCount)
        ''')

    def test_modern_combo_points_0_to_5_and_colors(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        FostercareTweaks_Config["Modern Combo Points"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame
        local cf=tf.comboFrame
        assert(cf and cf.pips and #cf.pips==5)

        -- 0 points: frame hidden
        comboPoints=0
        fire(tf,"OnEvent","PLAYER_COMBO_POINTS")
        assert(not cf:IsShown())

        -- 1 point: frame shown, pip 1 shown with amber/yellow color, pips 2-5 hidden
        comboPoints=1
        fire(tf,"OnEvent","PLAYER_COMBO_POINTS")
        assert(cf:IsShown())
        assert(cf.pips[1].fill:IsShown())
        local r,g,b = cf.pips[1].fill:GetVertexColor()
        assert(math.abs(r-1.0)<0.01 and math.abs(g-0.82)<0.01 and math.abs(b-0.0)<0.01)
        for i=2,5 do assert(not cf.pips[i].fill:IsShown()) end

        -- 3 points: pips 1-3 shown, pips 4-5 hidden
        comboPoints=3
        fire(tf,"OnEvent","PLAYER_COMBO_POINTS")
        assert(cf:IsShown())
        assert(cf.pips[1].fill:IsShown() and cf.pips[2].fill:IsShown() and cf.pips[3].fill:IsShown())
        assert(not cf.pips[4].fill:IsShown() and not cf.pips[5].fill:IsShown())

        -- 5 points: all 5 pips shown, pip 5 is red
        comboPoints=5
        fire(tf,"OnEvent","PLAYER_COMBO_POINTS")
        assert(cf:IsShown())
        for i=1,5 do assert(cf.pips[i].fill:IsShown()) end
        local r5,g5,b5 = cf.pips[5].fill:GetVertexColor()
        assert(math.abs(r5-1.0)<0.01 and math.abs(g5-0.20)<0.01 and math.abs(b5-0.20)<0.01)
        ''')

    def test_modern_combo_points_spending_and_target_switch(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        FostercareTweaks_Config["Modern Combo Points"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame
        local cf=tf.comboFrame

        -- Spend 5 points -> 0 points
        comboPoints=5
        fire(tf,"OnEvent","PLAYER_COMBO_POINTS")
        assert(cf:IsShown())
        comboPoints=0
        fire(tf,"OnEvent","PLAYER_COMBO_POINTS")
        assert(not cf:IsShown())

        -- Clear target -> frame hides
        local oldExists = UnitExists
        UnitExists = function(u) if u=="target" then return false end return oldExists(u) end
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(not tf:IsShown())
        assert(not cf:IsShown())

        -- Reacquire target with 2 points
        UnitExists = oldExists
        comboPoints=2
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf:IsShown())
        assert(cf:IsShown())
        assert(cf.pips[1].fill:IsShown() and cf.pips[2].fill:IsShown() and not cf.pips[3].fill:IsShown())
        ''')

    def test_modern_combo_points_toggle_and_native_restoration(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        FostercareTweaks_Config["Modern Combo Points"]=1
        UF:ApplyConfiguration()
        local tf=UF.targetFrame
        local cf=tf.comboFrame
        comboPoints=3
        fire(tf,"OnEvent","PLAYER_COMBO_POINTS")
        assert(cf:IsShown())

        -- Toggle Modern Combo Points off
        FostercareTweaks_Config["Modern Combo Points"]=0
        UF:ApplyConfiguration()
        assert(not cf:IsShown())

        -- Toggle Modern Combo Points back on
        FostercareTweaks_Config["Modern Combo Points"]=1
        UF:ApplyConfiguration()
        assert(cf:IsShown())
        assert(cf.pips[1].fill:IsShown() and cf.pips[2].fill:IsShown() and cf.pips[3].fill:IsShown())

        -- Switch to Standard Frames: native ComboFrame restored, modern frame suppressed
        FostercareTweaks_Config["Modern Target Frame"]=0
        UF:ApplyConfiguration()
        assert(not tf:IsShown())
        assert(not cf:IsShown())
        assert(ComboFrame.events["PLAYER_COMBO_POINTS"]==true)
        assert(ComboFrame.events["PLAYER_TARGET_CHANGED"]==true)

        -- Switch back to Modern Frames: native ComboFrame suppressed, modern frame active
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:ApplyConfiguration()
        assert(ComboFrame.events["PLAYER_COMBO_POINTS"]==nil)
        assert(tf.events["PLAYER_COMBO_POINTS"]==true)
        assert(cf:IsShown())
        ''')

    def test_modern_target_raid_marks_1_to_8_and_texcoords(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame
        assert(tf and tf.raidIcon)
        assert(tf.events["RAID_TARGET_UPDATE"]==true)

        -- Initially no mark -> raidIcon hidden
        raidTargets={target=nil}
        fire(tf,"OnEvent","RAID_TARGET_UPDATE")
        assert(not tf.raidIcon:IsShown())

        -- Test all 8 indices
        -- Index 1: Star (left 0, right 0.25, top 0, bottom 0.25)
        raidTargets.target=1
        fire(tf,"OnEvent","RAID_TARGET_UPDATE")
        assert(tf.raidIcon:IsShown())
        assert(tf.raidIcon.raidIndex==1)
        local c1=tf.raidIcon.texcoords
        assert(math.abs(c1[1]-0.0)<0.001 and math.abs(c1[2]-0.25)<0.001)
        assert(math.abs(c1[3]-0.0)<0.001 and math.abs(c1[4]-0.25)<0.001)

        -- Index 8: Skull (left 0.75, right 1.0, top 0.25, bottom 0.5)
        raidTargets.target=8
        fire(tf,"OnEvent","RAID_TARGET_UPDATE")
        assert(tf.raidIcon:IsShown())
        assert(tf.raidIcon.raidIndex==8)
        local c8=tf.raidIcon.texcoords
        assert(math.abs(c8[1]-0.75)<0.001 and math.abs(c8[2]-1.0)<0.001)
        assert(math.abs(c8[3]-0.25)<0.001 and math.abs(c8[4]-0.5)<0.001)

        -- Indices 2 through 7
        for idx=2,7 do
            raidTargets.target=idx
            fire(tf,"OnEvent","RAID_TARGET_UPDATE")
            assert(tf.raidIcon:IsShown())
            assert(tf.raidIcon.raidIndex==idx)
        end
        ''')

    def test_modern_target_raid_mark_clearing_and_target_switch(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame

        -- Active Skull on target
        raidTargets={target=8}
        fire(tf,"OnEvent","RAID_TARGET_UPDATE")
        assert(tf.raidIcon:IsShown())

        -- Mark cleared on target
        raidTargets.target=nil
        fire(tf,"OnEvent","RAID_TARGET_UPDATE")
        assert(not tf.raidIcon:IsShown())

        -- Target switch to marked target
        raidTargets.target=7 -- Cross
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.raidIcon:IsShown())
        assert(tf.raidIcon.raidIndex==7)

        -- Target loss -> frame and raidIcon hidden
        local oldExists = UnitExists
        UnitExists = function(u) if u=="target" then return false end return oldExists(u) end
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(not tf:IsShown())
        assert(not tf.raidIcon:IsShown())

        -- Target reacquisition without mark
        UnitExists = oldExists
        raidTargets.target=nil
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf:IsShown())
        assert(not tf.raidIcon:IsShown())

        -- Disable target frame hides raidIcon
        raidTargets.target=8
        fire(tf,"OnEvent","RAID_TARGET_UPDATE")
        assert(tf.raidIcon:IsShown())
        UF:DisableTargetFrame()
        assert(not tf:IsShown())
        assert(not tf.raidIcon:IsShown())
        ''')

    def test_modern_pvp_emblem_player_and_target_flags(self):
        lua=runtime(); lua.execute(r'''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Player Frame"]=1
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnablePlayerFrame()
        UF:EnableTargetFrame()
        local pf=UF.playerFrame
        local tf=UF.targetFrame

        -- Initial state: unflagged
        unitPVP={player=false, target=false}
        unitFFA={player=false, target=false}
        unitFaction={player="Alliance", target="Horde"}
        fire(pf,"OnEvent","PLAYER_FLAGS_CHANGED")
        fire(tf,"OnEvent","UNIT_FACTION","target")
        assert(not pf.pvpIcon:IsShown())
        assert(not tf.pvpIcon:IsShown())

        -- Flag player as Alliance PvP
        unitPVP.player=true
        fire(pf,"OnEvent","PLAYER_FLAGS_CHANGED")
        assert(pf.pvpIcon:IsShown())
        assert(pf.pvpIcon:GetWidth()==40 and pf.pvpIcon:GetHeight()==40)
        assert(string.find(pf.pvpIcon.texture[1] or "", "UI%-PVP%-Alliance"))

        -- Flag target as Horde PvP
        unitPVP.target=true
        fire(tf,"OnEvent","UNIT_FACTION","target")
        assert(tf.pvpIcon:IsShown())
        assert(tf.pvpIcon:GetWidth()==40 and tf.pvpIcon:GetHeight()==40)
        assert(string.find(tf.pvpIcon.texture[1] or "", "UI%-PVP%-Horde"))

        -- FFA flag overrides faction emblem on both
        unitFFA.player=true
        fire(pf,"OnEvent","PLAYER_FLAGS_CHANGED")
        assert(pf.pvpIcon:IsShown())
        assert(string.find(pf.pvpIcon.texture[1] or "", "UI%-PVP%-FFA"))

        unitFFA.target=true
        fire(tf,"OnEvent","UNIT_FACTION","target")
        assert(tf.pvpIcon:IsShown())
        assert(string.find(tf.pvpIcon.texture[1] or "", "UI%-PVP%-FFA"))

        -- Toggle Show PvP Emblem off hides both
        FostercareTweaks_Config["Show PvP Emblem"]=0
        fire(pf,"OnEvent","PLAYER_FLAGS_CHANGED")
        fire(tf,"OnEvent","UNIT_FACTION","target")
        assert(not pf.pvpIcon:IsShown())
        assert(not tf.pvpIcon:IsShown())

        -- Re-enable toggle restores icons
        FostercareTweaks_Config["Show PvP Emblem"]=1
        fire(pf,"OnEvent","PLAYER_FLAGS_CHANGED")
        fire(tf,"OnEvent","UNIT_FACTION","target")
        assert(pf.pvpIcon:IsShown())
        assert(tf.pvpIcon:IsShown())

        -- Target loss hides target pvpIcon
        local oldExists = UnitExists
        UnitExists = function(u) if u=="target" then return false end return oldExists(u) end
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(not tf.pvpIcon:IsShown())
        UnitExists = oldExists
        ''')

    def test_modern_target_level_and_difficulty_color(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame

        unitLevels={target=60}
        unitClassifications={target="normal"}
        difficultyColors={[60]={r=1, g=0.8, b=0}}

        -- Normal level 60 with difficulty color in dedicated levelBadge on portrait
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.levelBadge:IsShown())
        assert(tf.healthBar.levelText:IsShown())
        assert(tf.healthBar.levelText:GetText()=="60")
        local r, g, b = tf.healthBar.levelText:GetTextColor()
        assert(math.abs(r-1.0)<0.01 and math.abs(g-0.8)<0.01 and math.abs(b-0.0)<0.01)

        -- Health bar name is shown independently of levelBadge
        assert(tf.healthBar.nameText:IsShown())
        assert(tf.healthBar.nameText:GetText()=="target")

        -- Elite classification tag (+)
        unitClassifications.target="elite"
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.healthBar.levelText:GetText()=="60+")

        -- Rare elite classification tag (r+)
        unitClassifications.target="rareelite"
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.healthBar.levelText:GetText()=="60r+")

        -- Rare classification tag (r)
        unitClassifications.target="rare"
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.healthBar.levelText:GetText()=="60r")

        -- Worldboss classification tag (?? and red color)
        unitClassifications.target="worldboss"
        unitLevels.target=-1
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.healthBar.levelText:GetText()=="??")
        local br, bg, bb = tf.healthBar.levelText:GetTextColor()
        assert(math.abs(br-1.0)<0.01 and math.abs(bg-0.0)<0.01 and math.abs(bb-0.0)<0.01)

        -- Show Target Class option: default false, powerBar leftText is empty (no forced [60] ROGUE)
        assert(tf.powerBar.leftText:GetText()=="" or tf.powerBar.leftText:GetText()==nil)

        FostercareTweaks_Config["Show Target Class"]=1
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.powerBar.leftText:GetText()=="Priest")

        FostercareTweaks_Config["Show Target Class"]=0
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(tf.powerBar.leftText:GetText()=="")

        -- Show Target Level toggle off hides levelBadge and levelText
        FostercareTweaks_Config["Show Target Level"]=0
        fire(tf,"OnEvent","PLAYER_TARGET_CHANGED")
        assert(not tf.levelBadge:IsShown())
        assert(not tf.healthBar.levelText:IsShown())
        ''')

    def test_modern_frame_dimensions_and_live_updates(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Player Frame"]=1
        FostercareTweaks_Config["Modern Target Frame"]=1
        FostercareTweaks_Config["Modern Target of Target"]=1
        UF:EnablePlayerFrame()
        UF:EnableTargetFrame()
        UF:EnableToTFrame()
        local pf=UF.playerFrame
        local tf=UF.targetFrame
        local tot=UF.totFrame

        -- Default compact dimensions
        assert(pf:GetWidth()==200)
        assert(pf:GetHeight()==42)
        assert(tf:GetWidth()==200)
        assert(tf:GetHeight()==42)
        assert(tot:GetWidth()==120)
        assert(tot:GetHeight()==26)

        -- Custom dimensions via overwrites and ApplyDimensions
        FostercareTweaks_Config.overwrites={
            uf_player_width=240, uf_player_height=48,
            uf_target_width=250, uf_target_height=50,
            uf_tot_width=135, uf_tot_height=30,
            uf_power_height=12
        }
        UF:ApplyDimensions()

        assert(pf:GetWidth()==240)
        assert(pf:GetHeight()==48)
        assert(tf:GetWidth()==250)
        assert(tf:GetHeight()==50)
        assert(tot:GetWidth()==135)
        assert(tot:GetHeight()==30)
        assert(pf.powerBar:GetHeight()==12)
        assert(tf.powerBar:GetHeight()==12)
        assert(tot.powerBar:GetHeight()==12)

        -- Combo points remain anchored ABOVE target portrait
        local pt, relTo, relPt, x, y = tf.comboFrame:GetPoint()
        assert(pt=="BOTTOMLEFT")
        assert(relTo==tf.portrait)
        assert(relPt=="TOPLEFT")
        assert(x==0 and y==2)
        ''')

    def test_modern_frame_fonts_and_live_updates(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame

        FostercareTweaks_Config.overwrites={
            uf_font_name=14,
            uf_font_level=13,
            uf_font_health=12,
            uf_font_power=11
        }
        UF:ApplyFonts()

        local _, nameSize = tf.healthBar.nameText:GetFont()
        assert(nameSize==14)
        local _, levelSize = tf.healthBar.levelText:GetFont()
        assert(levelSize==13)
        local _, hpSize = tf.healthBar.healthText:GetFont()
        assert(hpSize==12)
        local _, pwrSize = tf.powerBar.powerText:GetFont()
        assert(pwrSize==11)
        ''')

    def test_modern_health_and_power_formats(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame

        -- Test UF.FormatHealthText across formats
        FostercareTweaks_Config.overwrites={uf_health_format="smart"}
        assert(UF.FormatHealthText(5000, 5000)=="5000")
        assert(UF.FormatHealthText(3500, 5000)=="3500 / 5000")

        FostercareTweaks_Config.overwrites={uf_health_format="current"}
        assert(UF.FormatHealthText(5000, 5000)=="5000")
        assert(UF.FormatHealthText(3500, 5000)=="3500")

        FostercareTweaks_Config.overwrites={uf_health_format="percent"}
        assert(UF.FormatHealthText(5000, 5000)=="100%")
        assert(UF.FormatHealthText(3500, 5000)=="70%")

        FostercareTweaks_Config.overwrites={uf_health_format="deficit"}
        assert(UF.FormatHealthText(5000, 5000)=="")
        assert(UF.FormatHealthText(3500, 5000)=="-1500")

        FostercareTweaks_Config.overwrites={uf_health_format="none"}
        assert(UF.FormatHealthText(5000, 5000)=="")
        assert(UF.FormatHealthText(3500, 5000)=="")

        -- Test UF.FormatPowerText across formats
        -- Rage (1) and Energy (3) always raw current value
        FostercareTweaks_Config.overwrites={uf_power_format="percent"}
        assert(UF.FormatPowerText(60, 100, 3)=="60")
        assert(UF.FormatPowerText(25, 100, 1)=="25")

        -- Mana (0):
        FostercareTweaks_Config.overwrites={uf_power_format="smart"}
        assert(UF.FormatPowerText(3000, 3000, 0)=="3000")
        assert(UF.FormatPowerText(1500, 3000, 0)=="1500 / 3000")

        FostercareTweaks_Config.overwrites={uf_power_format="current"}
        assert(UF.FormatPowerText(1500, 3000, 0)=="1500")

        FostercareTweaks_Config.overwrites={uf_power_format="percent"}
        assert(UF.FormatPowerText(1500, 3000, 0)=="50%")

        FostercareTweaks_Config.overwrites={uf_power_format="none"}
        assert(UF.FormatPowerText(1500, 3000, 0)=="")

        -- Live target frame reflection
        FostercareTweaks_Config.overwrites={uf_health_format="percent", uf_power_format="percent"}
        UF:ApplyConfiguration()
        assert(tf.healthBar.healthText:GetText()=="75%")
        assert(tf.powerBar.powerText:GetText()=="66%")
        ''')

    def test_modern_show_unit_name_toggle(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Player Frame"]=1
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnablePlayerFrame()
        UF:EnableTargetFrame()
        local pf=UF.playerFrame
        local tf=UF.targetFrame

        assert(UF:IsShowName()==true)
        assert(pf.healthBar.nameText:IsShown())
        assert(pf.healthBar.nameText:GetText()=="player")
        assert(tf.healthBar.nameText:IsShown())
        assert(tf.healthBar.nameText:GetText()=="target")

        FostercareTweaks_Config["Show Unit Name"]=0
        assert(UF:IsShowName()==false)
        UF:ApplyConfiguration()
        assert(not pf.healthBar.nameText:IsShown())
        assert(pf.healthBar.nameText:GetText()=="")
        assert(not tf.healthBar.nameText:IsShown())
        assert(tf.healthBar.nameText:GetText()=="")

        FostercareTweaks_Config["Show Unit Name"]=1
        assert(UF:IsShowName()==true)
        UF:ApplyConfiguration()
        assert(pf.healthBar.nameText:IsShown())
        assert(pf.healthBar.nameText:GetText()=="player")
        assert(tf.healthBar.nameText:IsShown())
        assert(tf.healthBar.nameText:GetText()=="target")
        ''')

    def test_modern_health_bar_height_clamping_for_large_fonts(self):
        lua=runtime(); lua.execute('''
        local UF=FostercareTweaks.UnitFrames
        FostercareTweaks_Config["Modern Target Frame"]=1
        UF:EnableTargetFrame()
        local tf=UF.targetFrame

        FostercareTweaks_Config.overwrites={
            uf_target_height=30,
            uf_power_height=20,
            uf_font_health=18
        }
        UF:ApplyDimensions()
        UF:ApplyFonts()

        local hpHeight = tf.healthBar:GetHeight()
        local pwHeight = tf.powerBar:GetHeight()

        assert(hpHeight >= 20)
        assert(hpHeight + pwHeight <= 30)
        ''')

    def test_blue_shaman_does_not_pollute_raid_class_colors_with_grey_fallback(self):
        lua = runtime()
        lua.execute(r'''
        dofile("mods/blue-shaman.lua")
        local mod = FostercareTweaks.mods["Blue Shaman Class Colors"]
        assert(mod ~= nil)
        mod:enable()

        assert(RAID_CLASS_COLORS["SHAMAN"] ~= nil)
        assert(RAID_CLASS_COLORS["SHAMAN"].r == 0.14)
        assert(RAID_CLASS_COLORS["SHAMAN"].g == 0.35)
        assert(RAID_CLASS_COLORS["SHAMAN"].b == 1.00)

        -- RAID_CLASS_COLORS must return nil for unknown keys, NOT grey fallback
        assert(RAID_CLASS_COLORS["UNKNOWN"] == nil)
        assert(RAID_CLASS_COLORS[""] == nil)
        assert(getmetatable(RAID_CLASS_COLORS) == nil)
        ''')

if __name__=='__main__': unittest.main(verbosity=2)
