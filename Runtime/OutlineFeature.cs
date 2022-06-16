using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class OutlineFeature : ScriptableRendererFeature
{
    class OutlineRenderPass : ScriptableRenderPass
    {
        private string profilingName;
        private Material material;
        
        private RenderTargetHandle jumpFloodRT;
        private RenderTargetHandle tempA;
        private RenderTargetHandle tempB;
        private RenderTargetHandle tempC;

        private RenderTargetIdentifier source { get; set; }


        public OutlineRenderPass(string profilingName, Material material)
        {
            this.material = material;
            this.profilingName = profilingName;
            tempA.Init("_TempA");
            tempB.Init("_TempB");
            tempC.Init("_TempC");
            jumpFloodRT.Init("_JumpFloodRT");
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // cameraTextureDescriptor.graphicsFormat = GraphicsFormat.R8G8B8A8_SRGB;
            cmd.GetTemporaryRT(jumpFloodRT.id, cameraTextureDescriptor);
            cmd.GetTemporaryRT(tempA.id, cameraTextureDescriptor);
            cmd.GetTemporaryRT(tempB.id, cameraTextureDescriptor);
            cmd.GetTemporaryRT(tempC.id, cameraTextureDescriptor);
        }

        public void Setup(RenderTargetIdentifier source)
        {
            this.source = source;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(profilingName);


             cmd.Blit(jumpFloodRT.id, tempA.id);
             // cmd.Blit(tempA.id,source);


             float[] d = { 16, 8, 4, 2, 1};
             for (int i = 0; i < d.Length; i++)
             {
                 cmd.SetGlobalFloat("_StepSize", d[i] + .5f);
            
                 if (i % 2 == 0)
                     cmd.Blit(tempA.id, tempB.id, material, 0);
                 else
                     cmd.Blit(tempB.id, tempA.id, material, 0);
             }
             
             cmd.SetGlobalTexture("_JumpFloodRT", tempA.id);

             
             // cmd.Blit(tempA.id,source);

            
            // cmd.Blit(tempA.id,source);


             cmd.Blit(source, tempC.id, material, 1);
             cmd.Blit(tempC.id, source);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(tempA.id);
            cmd.ReleaseTemporaryRT(tempB.id);
            cmd.ReleaseTemporaryRT(tempC.id);
            cmd.ReleaseTemporaryRT(jumpFloodRT.id);
            

        }
    }

    [System.Serializable]
    public class Settings
    {
        public Material material;
        public RenderPassEvent renderEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    [SerializeField] private Settings settings = new Settings();

    private OutlineRenderPass _outlineRenderPass;

    public override void Create()
    {
        _outlineRenderPass = new OutlineRenderPass(name, settings.material)
        {
            renderPassEvent = settings.renderEvent
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _outlineRenderPass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(_outlineRenderPass);
    }
}