using UnityEngine;
using System.Collections;
public class ParticleContral : MonoBehaviour {
    public Color BaseColor;
    public Color LinearColor;
    public Color FinalColor;
    public int ParticleCnt;
    public int hSliderValue;
    private Transform m_Transform; 
    private ParticleSystem m_ParticleSystem;
    private ParticleSystem.Particle[] m_particles;

    float width;
    float height;


    void Start()
    {
        width = Camera.main.pixelWidth*0.0159f;
        height = Camera.main.pixelHeight*0.0159f;
        m_Transform = gameObject.GetComponent<Transform>();
        m_ParticleSystem = gameObject.GetComponent<ParticleSystem>();
        var main = m_ParticleSystem.main;
        main.maxParticles = ParticleCnt;
        main.startLifetime = float.PositiveInfinity;

        var emission = m_ParticleSystem.emission;
        // emission.rateOverTime = hSliderValue;

        m_particles = new ParticleSystem.Particle[m_ParticleSystem.main.maxParticles];  //实例化，个数为粒子系统设置的最大粒子数.
	}

    Vector2 NoiseToDir(float a)
    {
        float angle = Mathf.PI*a;
        Vector3 ans = new Vector3(-0.3f, 0.5f, 0);
        ans.x = ans.x * Mathf.Cos(angle) - ans.y * Mathf.Sin(angle);
        ans.y = ans.x * Mathf.Sin(angle) + ans.y * Mathf.Cos(angle); 
        ans.z = 0;
        return ans;
    }

    void Update()
    {
        //获取当前激活的粒子.
        int num = m_ParticleSystem.GetParticles(m_particles);   
        float edge = num/4;
        if(m_ParticleSystem.isEmitting)
        {
            for (int i = 0; i < num; i++) 
            {
                // float noise = Perlin.Fbm(new Vector2(m_particles[i].position.x*0.01f, m_particles[i].position.y*0.01f), 4);

                // Vector3 Dir = NoiseToDir(noise).normalized;
                // m_particles[i].velocity = Dir;
                // m_particles[i].velocity = new Vector3(0, 1, 0);

                //left
                if(i < edge)
                    m_particles[i].position = new Vector3(-width/2,   (height/edge)*(float)(i-edge/2), 20f);
                //top
                else if(i < 2*edge)
                    m_particles[i].position = new Vector3((width/edge)*((float)i-edge-edge/2),   height/2, 20f);
                //right
                else if(i < 3*edge)
                    m_particles[i].position = new Vector3(width/2,   (height/edge)*((float)i-2*edge-edge/2), 20f);
                //bottom
                else if(i < 4*edge)
                    m_particles[i].position = new Vector3((width/edge)*((float)i-3*edge-edge/2),   -height/2, 20f);
            }
        }
        for (int i = 0; i < num; i++) 
        {

            m_particles[i].startColor = Color.Lerp(BaseColor, LinearColor, (m_particles[i].position.x+width/2)/width);
            m_particles[i].startColor = Color.Lerp(FinalColor, m_particles[i].startColor, (m_particles[i].position.y+height/2)/height);
            float noise = Perlin.Fbm(new Vector2(m_particles[i].position.x, m_particles[i].position.y), 2);
            
            Vector3 Dir = NoiseToDir(noise).normalized;
            if(i < edge)
                Dir = -Dir;
            if(i >= edge&&i < 2*edge)
                Dir = -Dir;
            // if(i >= 2*edge&&i < 3*edge)
            //     Dir = -Dir;
            if(i >= 3*edge&&i < 4*edge)
                Dir = -Dir;
            m_particles[i].velocity = 0.6f*Dir;
            // m_particles[i].velocity = m_particles[i].velocity.normalized;  
            // m_particles[i].startColor = Color.Lerp(m_particles[i].startColor, FinalColor, noise/0.3f);
            // m_particles[i].startColor = BaseColor;
        }
        m_ParticleSystem.SetParticles(m_particles, num);
    }
}