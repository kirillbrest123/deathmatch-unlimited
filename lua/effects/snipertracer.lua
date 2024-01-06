EFFECT.Mat = Material( "trails/smoke" )
EFFECT.Mat1 = Material( "effects/tracer_middle" )

EFFECT.Alpha = 255
EFFECT.Life = 0

function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()

	-- Keep the start and end pos - we're going to interpolate between them
	self.StartPos = self:GetTracerShootPos( self.Position, self.WeaponEnt, self.Attachment )

	self.EndPos = data:GetOrigin()

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

	self.TracerTime = math.min( 1, self.StartPos:Distance( self.EndPos ) / 30000)
	self.DieTime = CurTime() + self.TracerTime
	self.Dir = self.EndPos - self.StartPos
end

function EFFECT:Think()

	self.Life = self.Life + FrameTime() * 2
	self.Alpha = 255 * ( 1 - self.Life )

	return ( self.Life < 1 )

end

function EFFECT:Render()

	if ( self.Alpha < 1 ) then return end

	-- tracer

	local fDelta = ( self.DieTime - CurTime() ) / self.TracerTime
	fDelta = math.Clamp( fDelta, 0, 1 ) ^ 0.5
	local sinWave = math.sin( fDelta * math.pi )

	render.SetMaterial( self.Mat1 )


	render.DrawBeam( self.EndPos - self.Dir * ( fDelta - sinWave * 0.15 ),
		self.EndPos - self.Dir * ( fDelta + sinWave * 0.15 ),
		4, 1, 0, color_white )

	-- smoke

	render.SetMaterial( self.Mat )

	render.DrawBeam( self.StartPos,
		self.EndPos - self.Dir * ( fDelta + sinWave * 0.15 ),
		4,
		0,
		(self.StartPos - self.EndPos):Length() / 128,
		ColorAlpha(color_white, 128 * ( 1 - self.Life ) ) )

end