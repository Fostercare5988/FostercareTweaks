"""Headless Lua 5.1 UI/state regressions; rendering still needs WoW testing.
Run: python -B tests/test_frames.py [directory-containing-lupa]
"""
from pathlib import Path
import sys
import unittest
if len(sys.argv)>1: sys.path.insert(0,sys.argv.pop(1))
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
function methods:GetTop() return self.top end
function methods:ClearAllPoints() self.point=nil end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(self.point or {"TOPLEFT",UIParent,"TOPLEFT",0,0}) end
function methods:GetFrameLevel() return 1 end
function methods:SetTexture(...) self.texture={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetText(v) self.textValue=v end
function methods:GetText() return self.textValue end
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
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha or 1 end
function CreateFrame(kind,name,parent,template)
 local f={name=name,parent=parent,shown=true,width=64,height=34,scale=1,left=0,top=600,scripts={},events={}}
 setmetatable(f,{__index=function(t,k)
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
GameTooltip=CreateFrame("Frame","GameTooltip",UIParent)
function GameTooltip:SetUnitAura(unit,index,filter) self.lastAura={unit,index,filter} end
function GetTime() return now end
function IsShiftKeyDown() return shift end
function IsControlKeyDown() return ctrl end
function UnitExists(u) return u~=nil end
function UnitIsUnit(a,b) return a==b end
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
function UnitInRange() return true end
function UnitIsPlayer() return true end
function UnitPlayerControlled() return true end
function GetRaidTargetIndex() return nil end
function UnitThreatSituation() return 0 end
function GetNumRaidMembers() return raidCount or 0 end
function GetNumPartyMembers() return partyCount or 0 end
function GetRaidRosterInfo(i) return "Player"..i,0,math.ceil(i/5),60,"Priest","PRIEST","Zone",true,false end
function SetRaidTargetIconTexture() end
function SetMouseoverUnit(u) mouseover=u end
function TargetUnit(u) clickedUnit=u end
function SpellIsTargeting() return false end
function GetScreenWidth() return 1200 end
function GetScreenHeight() return 900 end
function ReloadUI() reloads=(reloads or 0)+1 end
function CooldownFrame_SetTimer(f,start,duration,enabled) f.timer={start,duration,enabled} end
C_Timer={NewTicker=function(delay,cb) local h={delay=delay,callback=cb}; table.insert(timers,h); return h end}
C_Spell={CancelSpellByID=function(id) table.insert(cancelled,id) end}
C_UnitAuras={}
function C_UnitAuras.UnitBuff(unit,i,filter) local t=auras[unit] and auras[unit].buffs; if t and t[i] then return unpack(t[i]) end end
function C_UnitAuras.UnitDebuff(unit,i,filter) local t=auras[unit] and auras[unit].debuffs; if t and t[i] then return unpack(t[i]) end end
FostercareTweaks_Config={overwrites={}}
FostercareTweaks={mods={},overwrites={},T=setmetatable({},{__index=function(t,k) return k end})}
function FostercareTweaks:register(m) self.mods[m.title]=m; return m end
function FostercareTweaks.Abbreviate(v) return tostring(v) end
function FostercareTweaks.HasUnitXP() return false end
function FostercareTweaks.HookScript() end
function FostercareTweaks.hooksecurefunc() end
function aura(name,id,expiration,source)
 return {name,"icon"..id,2,"Magic",30,expiration or 0,source or "raid1",false,false,id,false,false,true}
end
function visible(t) local n=0; for _,b in ipairs(t) do if b:IsShown() then n=n+1 end end; return n end
'''

def runtime():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    for name in ('move-unitframes','unitframes/core','unitframes/auras','unitframes/raid'):
        lua.execute((ROOT/'mods'/f'{name}.lua').read_text(encoding='utf-8'))
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

    def test_aura_position_survives_refresh_and_resize(self):
        lua=runtime(); lua.execute('''FostercareTweaks_Config.unitframe_positions={standard_target_buffs={point="TOPLEFT",relPoint="TOPLEFT",x=70,y=-90}}
        auras.target={buffs={aura("A",1),aura("B",2)}}
        local A=FostercareTweaks.UnitFrames.Auras; A:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        A:ApplyBuffSize(c,30); A:UpdateBlizzTargetAuras()
        assert(c.buffFrame.point[4]==70 and c.buffFrame.point[5]==-90)''')

    def test_aura_row_bounds_and_debuff_layout_cover_multiple_rows(self):
        lua=runtime(); lua.execute('''auras.target={buffs={},debuffs={aura("D",50)}}
        for i=1,12 do auras.target.buffs[i]=aura("B",i) end
        FostercareTweaks.UnitFrames.Auras:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        assert(c.buffFrame:GetHeight()==66)
        assert(c.debuffFrame.point[2]==c.buffFrame and c.debuffFrame.point[3]=="BOTTOMLEFT")''')

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
        assert(FCTweaksRaidFrame:GetHeight()==5*34+4*16+13+16)
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

    def test_empty_buff_area_does_not_push_debuffs_down(self):
        lua=runtime(); lua.execute('''auras.target={debuffs={aura("D",1)}}
        FostercareTweaks.UnitFrames.Auras:UpdateBlizzTargetAuras()
        local c=FostercareTweaks.UnitFrames.blizzTargetAuras
        assert(c.debuffFrame.point[2]==TargetFrame and c.debuffFrame.point[5]==32)''')

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

if __name__=='__main__': unittest.main(verbosity=2)
