# GPU-GEMS-3D-Fluid-Simulation

This project is based on the GPU Gems 3D fluid simulation article. This article presents a method for calculating and rendering 3D fluid simulations. The method used for rendering was designed to best integrate the fluid simulation into the scene and have it interact with other scene components. I have gone with a simpler renderer however by using a ray tracer that is attached to a cube and there is no interaction with other scene components.


This project was originally written when Unity 4 was current and at that time render textures were not available in the free version. I decided to use compute buffers instead to make it more accessible. The only down side to using compute buffers instead of render textures is that there is no support for filtering. I added the code to the shaders to manually do the bi-linear filtering but its probably not as optimal as using a render texture.

See [home page](https://www.digital-dust.com/single-post/2017/03/16/GPU-GEMS-to-Unity-3D-fluid-simulation) for more information.

![3D Fluid Simulation](https://static.wixstatic.com/media/1e04d5_897e2af2274d4af19f35c927401d541c~mv2.jpg/v1/fill/w_486,h_486,al_c,q_80,usm_0.66_1.00_0.01/1e04d5_897e2af2274d4af19f35c927401d541c~mv2.jpg)

