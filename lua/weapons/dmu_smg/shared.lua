SWEP.PrintName = "SMG"

SWEP.Author = ".kkrill"
SWEP.Instructions = "Fully-automatic submachine gun. Incredible fire rate at the cost of high spread and steep damage falloff. Best suited for close range combat."
SWEP.Category = "Deathmatch Unlimited"

SWEP.Spawnable = true

SWEP.Base = "weapon_dmu_base"

SWEP.WorldModel        = "models/weapons/w_smg1.mdl"
SWEP.ViewModel        = "models/weapons/c_smg1.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize        = 50        -- Size of a clip
SWEP.Primary.DefaultClip    = 200        -- Default number of bullets in a clip
SWEP.Primary.Ammo            = "SMG1"
SWEP.Primary.Automatic      = true

SWEP.Secondary.ClipSize        = 0
SWEP.Secondary.DefaultClip    = 0
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo            = ""

SWEP.VerticalRecoil            = 0.4
SWEP.HorizontalRecoil        = 0.3

SWEP.Scoped = true
SWEP.ADSZoom = 0.88

SWEP.Slot = 2
SWEP.SlotPos = 1

if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/dmu_smg" )
    killicon.AddAlias( "dmu_smg", "weapon_smg1" )
end

function SWEP:CInitialize()

    self:SetHoldType( "smg" )

end

function SWEP:PrimaryAttack()

    if ( !self:CanPrimaryAttack() ) then return end

    self:EmitSound( "Weapon_SMG1.Single" )

    local owner = self:GetOwner()

    local bullet = {}
    bullet.Num        = 1
    bullet.Src        = owner:GetShootPos()
    bullet.Dir        = owner:GetAimVector()
    bullet.Spread    = Vector(0.0225,0.0225,0)
    bullet.Tracer    = 2
    bullet.Force    = 1
    bullet.Damage    = 10
    bullet.AmmoType = self.Primary.Ammo

    bullet.Callback = function(attacker, tr, dmginfo)
        local dist = tr.StartPos:Distance(tr.HitPos)
        local falloff = 1 - math.Clamp((dist - 768) / 768, 0, 1) * 0.25 -- up to 25% damage falloff starting at 20m up to 40m
        dmginfo:ScaleDamage(falloff)
    end

    owner:FireBullets( bullet )

    self:ShootEffects()

    self:TakePrimaryAmmo( 1 )

    self:SetNextPrimaryFire( CurTime() + 0.06 )

    local rand = util.SharedRandom( self:GetClass(), -self.HorizontalRecoil, self.HorizontalRecoil )

    owner:ViewPunch( Angle( -self.VerticalRecoil * 0.5, rand * 0.5, 0 ) )

    if owner:IsPlayer() and (CLIENT or game.SinglePlayer()) and IsFirstTimePredicted() then -- fuck off. I trust my clients to not use cheats to mitigate this tiny recoil
        -- local rand = math.Rand( -self.HorizontalRecoil, self.HorizontalRecoil )

        local ang = owner:EyeAngles()

        ang.p = ang.p - self.VerticalRecoil
        ang.y = ang.y + rand

        owner:SetEyeAngles(ang)
    end
end

function SWEP:OnDrop()
    self:SetClip1(self.Primary.ClipSize)
end