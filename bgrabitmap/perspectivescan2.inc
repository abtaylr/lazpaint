{$asmmode intel}
    {$IFDEF PARAM_USESSE}
      asm
      {$IFDEF PARAM_USESHADER}
         mov eax, ShaderContext
         movaps xmm2, [eax+32] //positionInvZ
         movaps xmm3, [eax+48] //normalInvZ
      {$ENDIF}
      {$IFNDEF PARAM_USESOLIDCOLOR}
         xorps xmm5,xmm5
         movlps xmm5, texPos
      {$ENDIF}
      end;
    {$ENDIF}
      for i := ix1 to ix2 do
      begin
    {$IFDEF PARAM_USESSE}
      {$IFDEF PARAM_USEZBUFFER}
        if InvZPos > pzbuffer^ then
        begin
          pzbuffer^ := InvZPos;
      {$ENDIF}
          asm
             movss xmm4, InvZPos
             rcpss xmm4,xmm4         //zPos
             shufps xmm4,xmm4,0     //broadcast

           {$IFDEF PARAM_USESHADER}
             mov eax, ShaderContext

             mulps xmm2, xmm4       //positionInvZ*zPos (A)

             mulps xmm3, xmm4       //normalInvZ*zPos

             movaps [eax+0], xmm2   //(A) Position

             //normalize
             movaps xmm1, xmm3
             mulps xmm3, xmm3

             {$IFDEF PARAM_USESSE3}
             haddps xmm3,xmm3
             haddps xmm3,xmm3
             {$ELSE}
             //mix1
             movaps xmm7, xmm3
             shufps xmm7, xmm7, $4e
             addps xmm3, xmm7
             //mix2
             movaps xmm7, xmm3
             shufps xmm7, xmm7, $11
             addps xmm3, xmm7
             {$ENDIF}

             rsqrtps xmm3,xmm3

             mulps xmm3, xmm1  //apply

             movaps [eax+16], xmm3  //Normal
           {$ENDIF}

           {$IFNDEF PARAM_USESOLIDCOLOR}
             mulps xmm5, xmm4
             {$IFDEF PARAM_USEINTERPOLATION}
               movlps texPosByZ, xmm5
             {$ELSE}
               cvtps2dq xmm1,xmm5
               movlps intTexPos,xmm1
             {$ENDIF}
           {$ENDIF}
          end;
    {$ELSE}
      {$IFDEF PARAM_USEZBUFFER}
        if InvZPos > pzbuffer^ then
        begin
          pzbuffer^ := InvZPos;
      {$ENDIF}
        {$IFDEF PARAM_USESHADER}
          zPos := 1/InvZPos;
          with ShaderContext^ do
          begin
            Normal := NormalInvZ*zPos;
            Normalize3D_128(Normal);
            Position := PositionInvZ*zPos;
          end;
        {$ELSE}
          {$IFNDEF PARAM_USESOLIDCOLOR}
            zPos := 1/InvZPos;
          {$ENDIF}
        {$ENDIF}
    {$ENDIF}
          DrawPixelInlineWithAlphaCheck(pdest,
            {$IFDEF PARAM_USESHADER} ShaderFunction(ShaderContext, {$ENDIF}
            {$IFDEF PARAM_USELIGHTING} ApplyLightnessFast( {$ENDIF}
              {$IFDEF PARAM_USESOLIDCOLOR}
                solidColor
              {$ELSE}
                {$IFNDEF PARAM_USESSE}
                  {$IFDEF PARAM_USEINTERPOLATION}
                    scanAtFunc(texPos.x*zPos,texPos.y*zPos)
                  {$ELSE}
                    scanAtIntegerFunc(round(texPos.x*zPos),round(texPos.y*zPos))
                  {$ENDIF}
                {$ELSE}
                  {$IFDEF PARAM_USEINTERPOLATION}
                    scanAtFunc(texPosByZ.x,texPosByZ.y)
                  {$ELSE}
                    scanAtIntegerFunc(intTexPos.x,intTexPos.y)
                  {$ENDIF}
                {$ENDIF}
              {$ENDIF}
            {$IFDEF PARAM_USELIGHTING} ,light) {$ENDIF}
            {$IFDEF PARAM_USESHADER} ) {$ENDIF}
            );
      {$IFDEF PARAM_USEZBUFFER}
        end;
        inc(pzbuffer);
      {$ENDIF}

      {$IFDEF PARAM_USESSE}
        {$IFNDEF PARAM_USESOLIDCOLOR}
        asm
          movups xmm5, texPos
          movups xmm1, texStep
        end;
        InvZPos += zStep;
        asm
          addps xmm5, xmm1
          movlps texPos, xmm5
        end;
        {$ELSE}
        InvZPos += zStep;
        {$ENDIF}
      {$ELSE}
        {$IFNDEF PARAM_USESOLIDCOLOR}
        texPos.x += texStep.x;
        texPos.y += texStep.y;
        {$ENDIF}
        InvZPos += zStep;
      {$ENDIF}

      {$IFDEF PARAM_USESHADER}
        {$IFDEF PARAM_USESSE}
           asm
             mov eax, ShaderContext
             movaps xmm2, [eax+32] //PositionInvZ
             movaps xmm1, [eax+64] //PositionStepInvZ
             movaps xmm3, [eax+48] //NormalInvZ
             movaps xmm0, [eax+80] //NormalStepInvZ
             addps xmm2, xmm1
             addps xmm3, xmm0
             movaps [eax+32], xmm2
             movaps [eax+48], xmm3
           end;
{asm
  mov eax, ShaderContext
  movaps xmm2, [eax+32] //PositionInvZ
  movaps xmm1, [eax+64] //PositionStepInvZ
  addps xmm2, xmm1
  movaps [eax+32], xmm2

  movaps xmm3, [eax+48] //NormalInvZ
  movaps xmm1, [eax+80] //NormalStepInvZ
  addps xmm3, xmm1
  movaps [eax+48], xmm3
end;}
        {$ELSE}
          with ShaderContext^ do
          begin
            PositionInvZ += PositionStepInvZ;
            NormalInvZ += NormalStepInvZ;
          end;
        {$ENDIF}
      {$ENDIF}

      {$IFDEF PARAM_USELIGHTING}
        NextLight;
      {$ENDIF}
        inc(pdest);
      end;