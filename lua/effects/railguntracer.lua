EFFECT.Mat1 = Material( "effects/tool_tracer" )
EFFECT.Mat2 = Material( "trails/laser" )

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

end

function EFFECT:Think()

	self.Life = self.Life + FrameTime() * 0.8
	self.Alpha = 255 * ( 1 - self.Life )

	return ( self.Life < 1 )

end

function EFFECT:Render()

	if ( self.Alpha < 1 ) then return end

	local norm = (self.StartPos - self.EndPos) * self.Life

	self.Length = norm:Length()

	render.SetMaterial( self.Mat2 )
	render.DrawBeam( self.StartPos,
					self.EndPos,
					48,
					0,
					( ( self.StartPos - self.EndPos ):Length() / 128 ),
					Color( 255, 255, 255, 255 * ( 1 - self.Life ) ) )

	render.SetMaterial( self.Mat2 )
	render.DrawBeam( self.StartPos,
					self.EndPos,
					80,
					0,
					( ( self.StartPos - self.EndPos ):Length() / 128 ),
					Color( 255, 0, 0, 255 * ( 1 - self.Life ) ) )

end