"""Lua 5.1 ownership regressions; no in-game rendering claims.

Run: python -B tests/test_module_ownership.py [directory-containing-lupa]
Optional FT_TEST_REVISION tests a faulty Git revision without changing the tree.
Optional FT_TEXT_STATUS_BAR_SOURCE executes the pinned native redraw source.
"""
from pathlib import Path
import hashlib
import os
import subprocess
import sys
import unittest

if len(sys.argv) > 1 and Path(sys.argv[1]).is_dir():
    sys.path.insert(0, sys.argv.pop(1))
from lupa.lua51 import LuaRuntime
from test_frames import runtime as frame_runtime

ROOT = Path(__file__).resolve().parents[1]


def source(name):
    revision = os.environ.get("FT_TEST_REVISION")
    if revision:
        return subprocess.check_output(
            ["git", "show", f"{revision}:{name}"], cwd=ROOT, encoding="utf-8")
    return (ROOT / name).read_text(encoding="utf-8")


STUBS = r'''
frames={}; now=100; existing={}; guid={}; plates={}; casts={}; channels={}
classes={}; players={}; queries={}; messages={}; junk=2; sold=0; cursor=true
floor=math.floor; STANDARD_TEXT_FONT="test"; UNKNOWN="Unknown"
local methods={}
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:EnableMouse(value) self.mouse=value end
function methods:GetObjectType() return self.kind end
function methods:SetScript(k,f) self.scripts[k]=f end
function methods:GetScript(k) return self.scripts[k] end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale or 1 end
function methods:SetMovable(v) self.movable=v end
function methods:EnableKeyboard(v) self.keyboard=v end
function methods:EnableMouseWheel(v) self.mousewheel=v end
function methods:GetFrameLevel() return 1 end
function methods:GetFont() return 'test',12 end
function methods:SetTexture(v) self.texture=v end
function methods:GetTexture() return self.texture end
function methods:SetText(v) self.text=v and tostring(v) end
function methods:GetText() return self.text end
function methods:SetValue(v) self.value=v end
function methods:GetValue() return self.value or 500 end
function methods:SetMinMaxValues(a,b) self.minimum=a; self.maximum=b end
function methods:GetMinMaxValues() return self.minimum or 0,self.maximum or 1000 end
function methods:SetStatusBarColor(r,g,b) self.color={r,g,b} end
function methods:GetStatusBarColor() return unpack(self.color or {1,0,0}) end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha or 1 end
function methods:Enable() self.disabled=false end
function methods:Disable() self.disabled=true end
function methods:SetNormalTexture(v) self.normal=self:CreateTexture(); self.normal:SetTexture(v) end
function methods:GetNormalTexture() return self.normal end
function methods:GetRegions() return unpack(self.regions or {}) end
function methods:GetChildren() return self.healthbar end
function methods:GetNumChildren() return 0 end
function methods:CreateTexture(n) return CreateFrame('Texture',n,self) end
function methods:CreateFontString(n) return CreateFrame('FontString',n,self) end
for _,k in ipairs({'SetPoint','ClearAllPoints','SetAllPoints','SetFontObject',
 'SetFont','SetJustifyH','SetFrameStrata','SetFrameLevel','SetBackdrop',
 'SetBackdropBorderColor','SetStatusBarTexture','SetVertexColor','SetBlendMode',
 'SetDesaturated','SetOwner','SetTextColor','SetBackdropColor'}) do methods[k]=function() end end
function CreateFrame(kind,name,parent)
 local f={kind=kind,name=name,parent=parent,width=100,height=20,shown=true,scripts={},events={}}
 setmetatable(f,{__index=methods})
 table.insert(frames,f); if name then _G[name]=f end; return f
end
function fire(f,e,a,b,modern)
 local oldThis,oldEvent,oldA,oldB=this,event,arg1,arg2
 this,event,arg1,arg2=f,e,a,b
 if modern then f.scripts.OnEvent(f,e,a,b) else f.scripts.OnEvent() end
 this,event,arg1,arg2=oldThis,oldEvent,oldA,oldB
end
function GetTime() return now end
function UnitExists(u) return existing[u] or guid[u] or plates[u] end
function UnitGUID(u) return guid[u] or u end
function UnitName(u) return 'Same name' end
function UnitClass(u) return classes[u],classes[u] end
function UnitIsPlayer(u) return players[u] end
function UnitHealth() return 500 end
function UnitHealthMax() return 1000 end
function UnitIsDead() return dead end
function UnitIsGhost() return false end
function UnitLevel() return 60 end
function GetCVar() return '1' end
function GetNumPartyMembers() return 0 end
function ClearCursor() error('Must not mutate the user cursor') end
function UseContainerItem() error('Must not dispatch a slot-based item use') end
function hooksecurefunc(name,fn)
 local previous=_G[name]
 _G[name]=function(...) previous(...); fn(...) end
end
UIParent=CreateFrame('Frame','UIParent'); WorldFrame=CreateFrame('Frame','WorldFrame')
GameTooltip=CreateFrame('Frame','GameTooltip')
MerchantFrame=CreateFrame('Frame','MerchantFrame'); MerchantFrame.selectedTab=1
DEFAULT_CHAT_FRAME={AddMessage=function(_,s) table.insert(messages,s) end}
FostercareTweaks_Config={overwrites={}}
FostercareTweaks={mods={},T=setmetatable({},{__index=function(_,k) return k end})}
ShaguTweaks=FostercareTweaks
function FostercareTweaks:register(m) self.mods[m.title]=m; return m end
function FostercareTweaks.Abbreviate(n) return tostring(n) end
function FostercareTweaks.HasUnitXP() return false end
FostercareTweaks.hooksecurefunc=hooksecurefunc
RAID_CLASS_COLORS={MAGE={r=0.4,g=0.8,b=0.9},ROGUE={r=1,g=1,b=0.4}}
C_NamePlate={
 GetNamePlateForUnit=function(u) return plates[UnitGUID(u)] end,
 GetNamePlateForGUID=function(u) return plates[u] end,
 GetNamePlateGUIDs=function() local t={}; for g in pairs(plates) do table.insert(t,g) end; return t end
}
C_Spell={
 UnitCastingInfo=function(u) table.insert(queries,u); if casts[u] then return unpack(casts[u]) end end,
 UnitChannelInfo=function(u) if channels[u] then return unpack(channels[u]) end end
}
C_MerchantFrame={GetNumJunkItems=function() return junk end,
 SellAllJunkItems=function() sold=sold+1 end}
function MerchantFrame_Update() end
function plate(g)
 local p=CreateFrame('Button'); p.healthbar=CreateFrame('StatusBar')
 p.regions={p:CreateTexture(),p:CreateTexture(),p:CreateFontString()}
 p.regions[1]:SetTexture('Interface\\Tooltips\\Nameplate-Border')
 p.regions[3]:SetText('Same name'); plates[g]=p; return p
end
'''


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    return lua


def nameplates():
    lua = runtime()
    lua.execute(source("Helpers.lua"))
    for name, title in (("nameplate-castbar", "Nameplate Castbar"),
                        ("nameplate-classcolor", "Nameplate Class Colors")):
        lua.execute(source(f"mods/{name}.lua"))
        lua.execute(f'FostercareTweaks.mods["{title}"].enable()')
    lua.execute("""
        p=plate('0xA'); guid.nameplate1='0xA'; guid.target='0xB'; guid.mouseover='0xB'
        players['0xA']=true; classes['0xA']='MAGE'
        players.target=true; classes.target='ROGUE'
        fire(FCTweaksLibNameplate,'NAME_PLATE_UNIT_ADDED','nameplate1')
        function draw() this=p; p.scripts.OnUpdate() end
    """)
    return lua


def health():
    lua = runtime()
    lua.execute("""
        for _,u in ipairs({'Target','Player','Pet'}) do
            CreateFrame('Frame',u..'Frame')
            for _,kind in ipairs({'Health','Mana'}) do
                local b=CreateFrame('StatusBar',u..'Frame'..kind..'Bar')
                b.unit=string.lower(u); b.TextString=b:CreateFontString()
                b.lockShow=0; b.textLockable=true
            end
        end
        existing.target=true
        function TextStatusBar_UpdateTextString(b)
            b=b or this; b.TextString:SetText(b:GetValue()..' / '..select(2,b:GetMinMaxValues()))
            b.TextString:Show()
        end
    """)
    native = os.environ.get("FT_TEXT_STATUS_BAR_SOURCE")
    if native:
        blob = Path(native).read_bytes()
        git_hash = hashlib.sha1(b"blob " + str(len(blob)).encode() + b"\0" + blob).hexdigest()
        assert git_hash == "8417d749e9e14ce27b7aae3b760674b0ada8c8cc", "Unexpected native source"
        lua.execute(blob.decode())
    lua.execute(source("mods/health-numbers.lua"))
    lua.execute('FostercareTweaks.mods["Real Health Numbers"].enable()')
    return lua


class CoreTests(unittest.TestCase):
    def boot(self):
        lua = runtime()
        lua.execute('''
            FostercareTweaks=nil; ShaguTweaks={foreign=true}
            CLASSIC_API_VERSION=11515; SUPERWOW_VERSION='2.2'; SlashCmdList={}
            FostercareTweaks_Cache={players={}}; enabled={}
        ''')
        lua.execute(source('Core.lua'))
        return lua

    def chat_runtime(self, stored=None):
        lua = self.boot()
        lua.execute(source('Helpers.lua'))
        lua.globals().storedMessage = stored
        lua.execute('''
            NUM_CHAT_WINDOWS=1; strfind=string.find; CLOSE='Close'
            function GetRealmName() return 'Realm' end
            function date() return '12:34:56' end
            ChatFrame1=CreateFrame('Frame','ChatFrame1',UIParent)
            ChatFrame1.GetID=function() return 1 end
            chatOutput={}
            ChatFrame1.AddMessage=function(_,text) table.insert(chatOutput,text) end
            FostercareTweaks_Config['Chat Tweaks']=0
            FostercareTweaks_Config['Chat Hyperlinks']=0
            FostercareTweaks_Config['Chat History']=1
            FostercareTweaks_Config['Chat Timestamps']=1
            if storedMessage then
                FostercareTweaks_Cache.chathistory={Realm={['Same name']={[1]={storedMessage}}}}
            end
        ''')
        lua.execute(source('mods/chat-tweaks.lua'))
        return lua

    def test_chat_restore_keeps_original_timestamp_and_records_new_messages_once(self):
        stored = '|cffaaaaaa[01:02:03]|r previous message'
        lua = self.chat_runtime(stored)
        lua.execute('''
            FostercareTweaks:Initialize()
            assert(#chatOutput==1 and chatOutput[1]==storedMessage)
            ChatFrame1:AddMessage('new message',1,1,1)
            assert(#chatOutput==2)
            local history=FostercareTweaks_Cache.chathistory.Realm['Same name'][1]
            assert(#history==2 and history[2]==storedMessage)
            local _,n=string.gsub(history[1],'12:34:56','')
            assert(n==1 and string.find(history[1],'new message',1,true))
        ''')

    def test_chat_history_retains_the_last_thirty_messages(self):
        lua = self.chat_runtime()
        lua.execute('''
            FostercareTweaks_Config['Chat Timestamps']=0
            FostercareTweaks:Initialize()
            for i=1,35 do ChatFrame1:AddMessage('message '..i) end
            local history=FostercareTweaks_Cache.chathistory.Realm['Same name'][1]
            assert(#history==30 and history[1]=='message 35' and history[30]=='message 6')
        ''')

    def test_chat_history_recovers_invalid_saved_branches(self):
        for malformed in ("'invalid'", "{Realm=false}", "{Realm={['Same name']={ [1]='invalid' }}}"):
            lua = self.chat_runtime()
            lua.execute(f'FostercareTweaks_Cache.chathistory={malformed}')
            lua.execute('''
                FostercareTweaks:Initialize()
                ChatFrame1:AddMessage('message')
                assert(type(FostercareTweaks_Cache.chathistory)=='table')
                assert(#FostercareTweaks_Cache.chathistory.Realm['Same name'][1]==1)
                for _,msg in ipairs(messages) do assert(not string.find(msg,'Failed to enable',1,true)) end
            ''')

    def test_worldmap_mousewheel_stays_visible_and_preserves_scale_on_reopen(self):
        lua = self.boot()
        lua.execute(source('Helpers.lua'))
        lua.execute('''
            UISpecialFrames={}; UIPanelWindows={}
            WorldMapFrame=CreateFrame('Frame','WorldMapFrame',UIParent)
            WorldMapButton=CreateFrame('Button','WorldMapButton',WorldMapFrame)
            WorldMapDetailFrame=CreateFrame('Frame','WorldMapDetailFrame',WorldMapFrame)
            function IsShiftKeyDown() return shift end
            function IsControlKeyDown() return ctrl end
        ''')
        lua.execute(source('mods/worldmap-window.lua'))
        lua.execute('''
            FostercareTweaks.mods['WorldMap Window']:enable()
            local delay=frames[#frames]
            fire(delay,'PLAYER_ENTERING_WORLD')
            this=WorldMapFrame; ctrl=true; arg1=-100
            WorldMapFrame.scripts.OnMouseWheel(); assert(WorldMapFrame:GetScale()==0.3)
            arg1=100; WorldMapFrame.scripts.OnMouseWheel(); assert(WorldMapFrame:GetScale()==1.5)
            WorldMapFrame.scripts.OnShow(); assert(WorldMapFrame:GetScale()==1.5)
            ctrl=false; shift=true; arg1=-100
            WorldMapFrame.scripts.OnMouseWheel(); assert(WorldMapFrame:GetAlpha()==0.2)
            arg1=100; WorldMapFrame.scripts.OnMouseWheel(); assert(WorldMapFrame:GetAlpha()==1)
        ''')

    def test_initialization_prepares_all_defaults_before_enabling_in_registration_order(self):
        lua = self.boot()
        lua.execute('''
            FostercareTweaks:register({title='A',enabled=true,config={a=1},enable=function(self)
                assert(FostercareTweaks_Config.B==1, 'All defaults must be prepared first')
                assert(FostercareTweaks.overwrites.b==2)
                table.insert(enabled,'A')
            end})
            FostercareTweaks:register({title='B',enabled=true,config={b=2},enable=function(self)
                assert(self.config.a==nil, 'Config belongs to its module')
                table.insert(enabled,'B')
            end})
            local nativePairs=pairs
            pairs=function(t)
                if t==FostercareTweaks.mods then
                    local index=0; local keys={'B','A'}
                    return function() index=index+1; local key=keys[index]; if key then return key,t[key] end end
                end
                return nativePairs(t)
            end
            FostercareTweaks:Initialize()
            assert(table.concat(enabled,',')=='A,B')
            FostercareTweaks:Initialize(); assert(#enabled==2)
        ''')

    def test_saved_overwrites_are_applied_only_to_their_declaring_module(self):
        lua = self.boot()
        lua.execute('''
            FostercareTweaks_Config.overwrites={a=9,b=8,orphan='preserve'}
            FostercareTweaks:register({title='A',config={a=1}})
            FostercareTweaks:register({title='B',config={b=2}})
            FostercareTweaks:Initialize()
            assert(FostercareTweaks.mods.A.config.a==9 and FostercareTweaks.mods.A.config.b==nil)
            assert(FostercareTweaks.mods.B.config.b==8 and FostercareTweaks.mods.B.config.a==nil)
            assert(FostercareTweaks.overwrites.orphan==nil)
            assert(FostercareTweaks_Config.overwrites.orphan=='preserve')
        ''')

    def test_invalid_saved_root_tables_do_not_abort_startup(self):
        lua = self.boot()
        lua.execute('''
            FostercareTweaks_Config='invalid'; FostercareTweaks_Cache=false
            FostercareTweaks:register({title='A',enabled=true,enable=function() table.insert(enabled,'A') end})
            FostercareTweaks:Initialize()
            assert(#enabled==1 and type(FostercareTweaks_Config.overwrites)=='table')
            assert(type(FostercareTweaks_Cache.players)=='table')
        ''')

    def test_nested_sorted_iteration_does_not_mutate_or_invalidate_the_input(self):
        lua = self.boot()
        lua.execute(source('Helpers.lua'))
        lua.execute('''
            local t={b=2,a=1}; local visits=0
            for k,v in FostercareTweaks.spairs(t) do
                for inner in FostercareTweaks.spairs(t) do visits=visits+1 end
                assert(t.__orderedIndex==nil)
            end
            assert(visits==4 and t.a==1 and t.b==2)
        ''')

    def test_helpers_do_not_modify_an_independently_loaded_shagutweaks(self):
        lua = self.boot()
        lua.execute(source('Helpers.lua'))
        lua.execute('local n=0; for _ in pairs(ShaguTweaks) do n=n+1 end; assert(n==1 and ShaguTweaks.foreign)')

    def test_reagent_counter_uses_spell_identity_and_available_cast_count(self):
        lua = self.boot()
        lua.execute(source('Helpers.lua'))
        lua.execute('''
            NUM_ACTIONBAR_BUTTONS=1; actionType='spell'; actionID=123
            function HasAction(slot) return slot==1 end
            function GetActionInfo() return actionType,actionID end
            function GetActionTexture() return 'Interface\\\\Icons\\\\spell_nature_reincarnation' end
            function ActionButton_GetPagedID() return 1 end
            function IsConsumableAction() return false end
            function ActionButton_UpdateCount() end
            function GetMacroSpell() return 'Spell','Rank 1',macroSpell end
            function GetContainerNumSlots() return 0 end
            C_Item={GetItemCount=function() return 12 end}
            table.wipe=function(t) for key in pairs(t) do t[key]=nil end end
            C_Timer={After=function(_,callback) reagentCallback=callback end}
            C_Spell.GetSpellReagents=function(id)
                if id==123 then return {{itemID=456,count=3},{itemID=789,count=1}} end
                return {}
            end
            C_Spell.GetSpellCastCount=function(id) assert(id==123); return castCount or 4 end
            ActionButton1=CreateFrame('Button','ActionButton1',UIParent)
            ActionButton1Count=CreateFrame('FontString','ActionButton1Count',ActionButton1)
        ''')
        lua.execute(source('mods/actionbar-reagents.lua'))
        lua.execute('''
            FostercareTweaks.mods['Reagent Counter']:enable()
            assert(ActionButton1Count:GetText()=='4', 'Use all reagent requirements')
            castCount=2
            fire(FCTweaksReagentCount,'BAG_UPDATE')
        ''')
        # Run either the old next-frame handler or the new deferred callback.
        lua.execute('''
            if FCTweaksReagentCount.scripts.OnUpdate then this=FCTweaksReagentCount; this.scripts.OnUpdate()
            else reagentCallback() end
            assert(ActionButton1Count:GetText()=='2')
        ''')

    def test_failed_dependency_guard_stops_the_entire_manifest(self):
        for version, superwow in ((11514, "'2.2'"), ("nil", "'2.2'"), (11515, "nil")):
            lua = runtime()
            lua.execute(f'FostercareTweaks=nil; CLASSIC_API_VERSION={version}; SUPERWOW_VERSION={superwow}; SlashCmdList={{}}; initialFrames=#frames')
            for line in (ROOT/'FostercareTweaks.toc').read_text().splitlines():
                if line.strip() and not line.startswith('#'):
                    lua.execute(source(line.replace('\\','/')))
            lua.execute('assert(FostercareTweaks==nil and #frames==initialFrames)')

    def test_reagents_preserve_native_this_macro_identity_and_item_stack_counts(self):
        lua = self.boot()
        lua.execute('''
            NUM_ACTIONBAR_BUTTONS=3; actions={[1]={'macro',7},[2]={'spell',456},[3]={'item',5140}}
            table.wipe=function(t) for k in pairs(t) do t[k]=nil end end
            C_Timer={After=function(_,fn) reagentCallback=fn end}
            function GetActionInfo(slot) if actions[slot] then return unpack(actions[slot]) end end
            function GetMacroSpell(id) assert(id==7); if not unknownMacro then return 'Spell','Rank',123 end end
            function ActionButton_GetPagedID(button) return button.slot end
            function IsConsumableAction(slot) return slot==3 end
            function GetActionCount(slot) assert(slot==3); return 17 end
            -- Native 1.12.1 ActionButton.lua: UpdateCount reads global this,
            -- ignores its arguments and clears labels on non-consumable actions.
            function ActionButton_UpdateCount()
                local text=_G[this:GetName()..'Count']
                if IsConsumableAction(ActionButton_GetPagedID(this)) then
                    text:SetText(GetActionCount(ActionButton_GetPagedID(this)))
                else text:SetText('') end
            end
            C_Spell.GetSpellReagents=function(id) if id==123 then return {{itemID=5140,count=3}} end; return {} end
            C_Spell.GetSpellCastCount=function(id) assert(id==123); return 4 end
            for i=1,3 do
                local b=CreateFrame('Button','ActionButton'..i,UIParent); b.slot=i
                CreateFrame('FontString','ActionButton'..i..'Count',b)
            end
            outerFrame=CreateFrame('Frame',nil,UIParent); this=outerFrame
        ''')
        lua.execute(source('mods/actionbar-reagents.lua'))
        lua.execute('''
            FostercareTweaks.mods['Reagent Counter']:enable()
            assert(this==outerFrame and ActionButton1Count:GetText()=='4')
            assert(ActionButton2Count:GetText()=='' and ActionButton3Count:GetText()=='17')
            unknownMacro=true; fire(FCTweaksReagentCount,'UPDATE_MACROS',nil,nil,true)
            reagentCallback()
            assert(this==outerFrame and ActionButton1Count:GetText()=='')
            actions[1]={'spell',123}; fire(FCTweaksReagentCount,'ACTIONBAR_SLOT_CHANGED',0,nil,true)
            reagentCallback(); assert(ActionButton1Count:GetText()=='4')
            assert(ActionButton3Count:GetText()=='17')
        ''')

    def test_unnamed_cooldowns_do_not_share_an_overlay(self):
        lua = self.boot()
        lua.execute(source('Helpers.lua'))
        lua.execute('''
            function CooldownFrame_SetTimer() end
            function GetActionCooldown() return 0,0,0 end
            function HasAction() return false end
        ''')
        lua.execute(source('mods/cooldown-numbers.lua'))
        lua.execute('''
            FostercareTweaks.mods['Cooldown Numbers']:enable()
            local parent=CreateFrame('Frame',nil,UIParent)
            parent.GetHeight=function() return 24 end
            local a,b=CreateFrame('Model',nil,parent),CreateFrame('Model',nil,parent)
            CooldownFrame_SetTimer(a,100,60,1); CooldownFrame_SetTimer(b,100,120,1)
            assert(a.cooldowntext~=b.cooldowntext,'Each cooldown owns its text')
            assert(a.cooldowntext:GetParent()==a and b.cooldowntext:GetParent()==b)
            assert(a.cooldowntext.duration==60 and b.cooldowntext.duration==120)
        ''')


class OwnershipTests(unittest.TestCase):
    def test_native_target_timer_does_not_restart_on_unchanged_redraw(self):
        lua = frame_runtime()
        lua.execute("""
            MAX_TARGET_DEBUFFS=1
            FostercareTweaks_Config['Improved Standard Auras']=0
            FostercareTweaks.TimeConvert=tostring
            auras.target={debuffs={aura('Poison',123,130,'player')}}
        """)
        lua.execute(source('mods/target-debufftimer.lua'))
        lua.execute("""
            FostercareTweaks.mods['Debuff Timer'].enable()
            TargetDebuffButton_Update()
            local cd=TargetFrameDebuff1.cd; local n=cd.sequenceCalls
            TargetDebuffButton_Update(); assert(cd.sequenceCalls==n)
            auras.target.debuffs[1][7]='party1'
            TargetDebuffButton_Update(); assert(cd.sequenceCalls==n+1)
            unitGUIDs.target='New target'
            TargetDebuffButton_Update(); assert(cd.sequenceCalls==n+2)
            auras.target.debuffs[1][6]=0
            TargetDebuffButton_Update(); assert(not cd:IsShown())
            auras.target.debuffs[1][6]=130
            TargetDebuffButton_Update(); assert(cd.sequenceCalls==n+3)
        """)

    def test_health_format_survives_repeated_native_redraw(self):
        health().execute("""
            TextStatusBar_UpdateTextString(TargetFrameHealthBar)
            assert(TargetFrameHealthBar.TextString:GetText()=='500 - 50%')
            TextStatusBar_UpdateTextString(TargetFrameHealthBar)
            assert(TargetFrameHealthBar.TextString:GetText()=='500 - 50%')
            this=PlayerFrameHealthBar; TextStatusBar_UpdateTextString()
            TextStatusBar_UpdateTextString()
            assert(PlayerFrameHealthBar.TextString:GetText()=='500')
        """)

    def test_dead_target_stays_empty_after_native_redraw(self):
        health().execute("""
            dead=true; TextStatusBar_UpdateTextString(TargetFrameHealthBar)
            TextStatusBar_UpdateTextString(TargetFrameHealthBar)
            assert(TargetFrameHealthBar.TextString:GetText()=='')
            assert(not TargetFrameHealthBar.TextString:IsShown())
        """)

    def test_health_hook_does_not_own_other_addon_bars(self):
        health().execute("""
            local b=CreateFrame('StatusBar','OtherAddonHealthBar'); b.unit='player'
            b.TextString=b:CreateFontString(); b.lockShow=0; b.textLockable=true
            TextStatusBar_UpdateTextString(b)
            assert(b.TextString:GetText()=='500 / 1000' and b.lockShow==0)
        """)

    def test_same_name_target_and_mouseover_cannot_supply_plate_cast(self):
        nameplates().execute("""
            casts['0xA']={'Correct','Correct','a',100000,104000,false,nil,false}
            casts.target={'Wrong','Wrong','b',100000,108000,false,nil,false}
            casts.mouseover=casts.target; draw()
            assert(p.castbar.text:GetText()=='Correct')
            casts['0xA']=nil; draw(); assert(not p.castbar:IsShown())
        """)

    def test_nameplate_class_uses_live_identity_and_native_redraw(self):
        nameplates().execute("""
            draw(); assert(p.healthbar.color[1]==0.4)
            assert(FostercareTweaks_Cache.players['Same name'].class=='MAGE')
            p.healthbar:SetStatusBarColor(1,0,0); draw()
            assert(p.healthbar.color[1]==0.4)
            classes['0xA']='ROGUE'; draw(); assert(p.healthbar.color[1]==1)
        """)

    def test_recycled_frame_clears_cast_until_new_owner_is_bound(self):
        nameplates().execute("""
            casts['0xA']={'Old','Old','a',100000,104000,false,nil,false}; draw()
            plates['0xA']=nil; plates['0xB']=p; draw()
            assert(not p.castbar:IsShown())
            guid.nameplate1='0xB'
            casts['0xB']={'New','New','b',100000,105000,false,nil,false}
            fire(FCTweaksLibNameplate,'NAME_PLATE_UNIT_ADDED','nameplate1',nil,true)
            draw(); assert(p.castbar.text:GetText()=='New')
        """)

    def test_removed_old_binding_cannot_erase_new_binding(self):
        nameplates().execute("""
            plates['0xB']=p; guid.nameplate2='0xB'
            fire(FCTweaksLibNameplate,'NAME_PLATE_UNIT_ADDED','nameplate2')
            fire(FCTweaksLibNameplate,'NAME_PLATE_UNIT_REMOVED','nameplate1')
            assert(p.unit=='0xB')
            fire(FCTweaksLibNameplate,'NAME_PLATE_UNIT_REMOVED','nameplate2')
            assert(p.unit==nil)
        """)

    def test_world_entry_binds_existing_plates_without_worldframe_polling(self):
        nameplates().execute("""
            p.unit=nil; fire(FCTweaksLibNameplate,'PLAYER_ENTERING_WORLD')
            assert(p.unit=='0xA')
            assert(FCTweaksLibNameplate:GetScript('OnUpdate')==nil)
        """)

    def test_channel_unknown_timing_and_expired_cast_remain_hidden(self):
        nameplates().execute("""
            channels['0xA']={'Channel','Channel','a',nil,nil,false,false}; draw()
            assert(not p.castbar:IsShown())
            channels['0xA']={'Channel','Channel','a',99000,102000,false,false}; draw()
            assert(p.castbar:IsShown() and p.castbar:GetValue()==2)
            now=103; draw(); assert(not p.castbar:IsShown())
        """)

    def test_sell_junk_delegates_once_without_clearing_cursor_or_claiming_success(self):
        lua = runtime()
        lua.execute(source("mods/sell-junk.lua"))
        lua.execute("""
            FostercareTweaks.mods['Sell Junk'].enable()
            FCTweaksSellJunkButton.scripts.OnClick()
            assert(sold==1 and cursor and #messages==0)
            for _,f in ipairs(frames) do assert(not f.scripts.OnUpdate) end
        """)

    def test_sell_button_tracks_native_redraw_empty_bags_and_closed_merchant(self):
        lua = runtime()
        lua.execute(source("mods/sell-junk.lua"))
        lua.execute("""
            FostercareTweaks.mods['Sell Junk'].enable()
            assert(not FCTweaksSellJunkButton.disabled)
            junk=0; MerchantFrame_Update(); assert(FCTweaksSellJunkButton.disabled)
            MerchantFrame.selectedTab=2; MerchantFrame_Update()
            assert(not FCTweaksSellJunkButton:IsShown())
            FCTweaksSellJunkButton.scripts.OnClick(); assert(sold==0)
            MerchantFrame.selectedTab=1; MerchantFrame:Hide()
            FCTweaksSellJunkButton.scripts.OnClick(); assert(sold==0)
        """)

    def test_tot_restarts_sampling_after_target_loss_and_reacquisition(self):
        lua = frame_runtime()
        lua.execute(source("mods/unitframes/tot.lua"))
        lua.execute("""
            local UF=FostercareTweaks.UnitFrames
            UF:EnableToTFrame(); local f=FCTweaksToTFrame
            local ticker
            for _,v in ipairs(frames) do if v.scripts.OnUpdate then ticker=v end end
            assert(ticker)
            local nativeExists=UnitExists
            UnitExists=function(u) if u=='target' or u=='targettarget' then return false end; return nativeExists(u) end
            event='PLAYER_TARGET_CHANGED'; f.scripts.OnEvent(); this=ticker; ticker.scripts.OnUpdate()
            assert(not ticker:IsShown())
            UnitExists=nativeExists; event='PLAYER_TARGET_CHANGED'; f.scripts.OnEvent()
            assert(ticker:IsShown())
        """)

    def test_tot_world_entry_recovers_while_frame_is_hidden(self):
        lua = frame_runtime()
        lua.execute(source("mods/unitframes/tot.lua"))
        lua.execute("""
            FostercareTweaks.UnitFrames:EnableToTFrame()
            FCTweaksToTFrame:Hide(); event='PLAYER_ENTERING_WORLD'
            FCTweaksToTFrame.scripts.OnEvent(); assert(FCTweaksToTFrame:IsShown())
            FostercareTweaks.UnitFrames:DisableToTFrame()
            assert(not FCTweaksToTFrame:IsShown() and next(FCTweaksToTFrame.events)==nil)
        """)


if __name__ == '__main__':
    unittest.main(verbosity=2)
