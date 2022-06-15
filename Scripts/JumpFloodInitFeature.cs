using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class JumpFloodInitFeature : ScriptableRendererFeature
{
    class JumpFloodRenderPass : ScriptableRenderPass
    {
        private string profilingName;
        private Material material;
        private RenderTargetHandle jumpFloodRT;
        private readonly List<ShaderTagId> m_ShaderTagId;
        private FilteringSettings m_FilteringSettings;
        private ProfilingSampler m_ProfilingSampler;


        public JumpFloodRenderPass(RenderQueueRange renderQueueRange, LayerMask layerMask, string profilingName,
            Material material)
        {
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
            this.material = material;
            this.profilingName = profilingName;
            jumpFloodRT.Init("_JumpFloodRT");
            m_ShaderTagId = new List<ShaderTagId>
            {
                new ShaderTagId("SRPDefaultUnlit"),
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("UniversalForwardOnly"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("JFA")
            };
            m_ProfilingSampler = new ProfilingSampler("JumpFlood");
        }


        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            cmd.GetTemporaryRT(jumpFloodRT.id, cameraTextureDescriptor);
            ConfigureTarget(jumpFloodRT.id);
            ConfigureClear(ClearFlag.All, Color.blue);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(profilingName);

            SortingCriteria sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;

            DrawingSettings drawSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, sortFlags);
            drawSettings.overrideMaterial = material;
            drawSettings.overrideMaterialPassIndex = 0;


            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);
            }

            cmd.SetGlobalTexture("_JumpFloodRT", jumpFloodRT.id);

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(jumpFloodRT.id);
        }
    }

    [System.Serializable]
    public class Settings
    {
        public Material material;
        public RenderPassEvent renderEvent = RenderPassEvent.AfterRenderingTransparents;
        public LayerMask layerMask;
    }

    [SerializeField] private Settings settings = new Settings();
    private JumpFloodRenderPass _jumpFloodRenderPass;

    public override void Create()
    {
        _jumpFloodRenderPass =
            new JumpFloodRenderPass(RenderQueueRange.all, settings.layerMask, name, settings.material)
            {
                renderPassEvent = settings.renderEvent
            };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_jumpFloodRenderPass);
    }
}