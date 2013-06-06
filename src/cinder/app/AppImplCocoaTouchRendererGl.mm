/*
 Copyright (c) 2012, The Cinder Project, All rights reserved.

 This code is intended for use with the Cinder C++ library: http://libcinder.org

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that
 the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and
	the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
	the following disclaimer in the documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/

#import "AppImplCocoaTouchRendererGl.h"
#import <QuartzCore/QuartzCore.h>

#include "cinder/gl/gl.h"


@interface AppImplCocoaTouchRendererGl ()

- (void)layoutSubviews;
- (void)allocateGraphics:(cinder::app::RendererGlRef)sharedRenderer;

@end

@implementation AppImplCocoaTouchRendererGl

- (id)initWithFrame:(CGRect)frame cinderView:(UIView*)cinderView app:(cinder::app::App*)app renderer:(cinder::app::RendererGl*)renderer sharedRenderer:(cinder::app::RendererGlRef)sharedRenderer
{
	mCinderView = cinderView;
	mApp = app;

	CAEAGLLayer *eaglLayer = (CAEAGLLayer *)cinderView.layer;
	eaglLayer.opaque = TRUE;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

	mBackingWidth	= 0;
	mBackingHeight	= 0;
	
	mPointsWidth	= 0;
	mPointsHeight	= 0;
	
	
	mMsaaSamples = cinder::app::RendererGl::sAntiAliasingSamples[renderer->getAntiAliasing()];
	mUsingMsaa = mMsaaSamples > 0;

	[self allocateGraphics:sharedRenderer];

	return self;	
}

- (void)allocateGraphics:(cinder::app::RendererGlRef)sharedRenderer
{

// OLD:
//	mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
// NEW:
//----->
// 	if( sharedRenderer ) {
// 		EAGLSharegroup *sharegroup = [sharedRenderer->getEaglContext() sharegroup];
// 		mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1 sharegroup:sharegroup];
// 	}
// 	else
// 		mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
//----->
// PROPOSED:
  if( sharedRenderer ) {
    EAGLSharegroup *sharegroup = [sharedRenderer->getEaglContext() sharegroup];
    mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup];
  }
  else
    mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

	if( ( ! mContext ) || ( ! [EAGLContext setCurrentContext:mContext] ) ) {
		[self release];
		return;
	}
	
	// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
//OLD:
//----->
// 	glGenFramebuffers( 1, &defaultFramebuffer );
// 	glGenRenderbuffers( 1, &colorRenderbuffer );
// 	glBindFramebuffer( GL_FRAMEBUFFER, defaultFramebuffer );
// 	glBindRenderbuffer( GL_RENDERBUFFER, colorRenderbuffer );
// 	glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer );
// 
// 	glGenRenderbuffers( 1, &depthRenderbuffer );
// 	glBindRenderbuffer( GL_RENDERBUFFER, depthRenderbuffer );
// 	glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight );
// 	glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer );
//----->
//NEW:
//----->
// 	glGenFramebuffersOES( 1, &mViewFramebuffer );
// 	glGenRenderbuffersOES( 1, &mViewRenderBuffer );
// 	glBindFramebufferOES( GL_FRAMEBUFFER_OES, mViewFramebuffer );
// 	glBindRenderbufferOES( GL_RENDERBUFFER_OES, mViewRenderBuffer );
// 	glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, mViewRenderBuffer );
// 
// 	if( mUsingMsaa ) {
// 		glGenFramebuffersOES( 1, &mMsaaFramebuffer );
// 		glGenRenderbuffersOES( 1, &mMsaaRenderBuffer );
// 		
// 		glBindFramebufferOES( GL_FRAMEBUFFER_OES, mMsaaFramebuffer );
// 		glBindRenderbufferOES( GL_RENDERBUFFER_OES, mMsaaRenderBuffer );
// 		
// 		glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_RGB5_A1_OES, 0, 0 );
// 		glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, mMsaaRenderBuffer );
// 
// 		glGenRenderbuffersOES( 1, &mDepthRenderBuffer );		
// 		glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
// 		glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_DEPTH_COMPONENT16_OES, 0, 0  );
// 		glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthRenderBuffer );
// 	}
// 	else {
// 		glGenRenderbuffersOES( 1, &mDepthRenderBuffer );
// 		glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
// 		glRenderbufferStorageOES( GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, 0, 0 );
// 		glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthRenderBuffer );
// 	}
//----->
//PROPOSED:

#if ! defined ( CINDER_GLES2 )
  glGenFramebuffersOES( 1, &mViewFramebuffer );
  glGenRenderbuffersOES( 1, &mViewRenderBuffer );
  glBindFramebufferOES( GL_FRAMEBUFFER_OES, mViewFramebuffer );
  glBindRenderbufferOES( GL_RENDERBUFFER_OES, mViewRenderBuffer );
  glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, mViewRenderBuffer );

  if( mUsingMsaa ) {
    glGenFramebuffersOES( 1, &mMsaaFramebuffer );
    glGenRenderbuffersOES( 1, &mMsaaRenderBuffer );
    
    glBindFramebufferOES( GL_FRAMEBUFFER_OES, mMsaaFramebuffer );
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, mMsaaRenderBuffer );
    
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_RGB5_A1_OES, 0, 0 );
    glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, mMsaaRenderBuffer );

    glGenRenderbuffersOES( 1, &mDepthRenderBuffer );    
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_DEPTH_COMPONENT16_OES, 0, 0  );
    glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthRenderBuffer );
  }
  else {
    glGenRenderbuffersOES( 1, &mDepthRenderBuffer );
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
    glRenderbufferStorageOES( GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, 0, 0 );
    glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthRenderBuffer );
  }
#else
  glGenFramebuffers( 1, &mViewFramebuffer );
  glGenRenderbuffers( 1, &mViewRenderBuffer );
  glBindFramebuffer( GL_FRAMEBUFFER, mViewFramebuffer );
  glBindRenderbuffer( GL_RENDERBUFFER, mViewRenderBuffer );
  glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mViewRenderBuffer );

  if( mUsingMsaa ) {
    glGenFramebuffers( 1, &mMsaaFramebuffer );
    glGenRenderbuffers( 1, &mMsaaRenderBuffer );
    
    glBindFramebuffer( GL_FRAMEBUFFER, mMsaaFramebuffer );
    glBindRenderbuffer( GL_RENDERBUFFER, mMsaaRenderBuffer );
    
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER, mMsaaSamples, GL_RGB5_A1, 0, 0 );
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mMsaaRenderBuffer );

    glGenRenderbuffers( 1, &mDepthRenderBuffer );
    glBindRenderbuffer( GL_RENDERBUFFER, mDepthRenderBuffer );
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER, mMsaaSamples, GL_DEPTH_COMPONENT16, 0, 0  );
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mDepthRenderBuffer );
  }
  else {
    glGenRenderbuffers( 1, &mDepthRenderBuffer );
    glBindRenderbuffer( GL_RENDERBUFFER, mDepthRenderBuffer );
    glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, 0, 0 );
    glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mDepthRenderBuffer );
  }
#endif
}

- (EAGLContext*)getEaglContext
{
	return mContext;
}

- (void)layoutSubviews
{
	[EAGLContext setCurrentContext:mContext];
	// Allocate color buffer backing based on the current layer size
//OLD:
//----->
// 	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
// 	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)cinderView.layer];
// 	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
// 	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
// 
// 	glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
// 	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
// 	
// 	if( glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE ) {
// 		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
//----->
//NEW:
//----->
// 	glBindFramebufferOES( GL_FRAMEBUFFER_OES, mViewFramebuffer );
// 	glBindRenderbufferOES( GL_RENDERBUFFER_OES, mViewRenderBuffer );
// 	[mContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)mCinderView.layer];
// 	glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &mBackingWidth );
// 	glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &mBackingHeight );
// 
// 	if( mUsingMsaa ) {
// 		glBindFramebufferOES( GL_FRAMEBUFFER_OES, mMsaaFramebuffer );
// 		glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
// 		glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_DEPTH_COMPONENT16_OES, mBackingWidth, mBackingHeight );
// 		glBindRenderbufferOES( GL_RENDERBUFFER_OES, mMsaaRenderBuffer );
// 		glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_RGB5_A1_OES, mBackingWidth, mBackingHeight );		
// 	}
// 	else {
// 		glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
// 		glRenderbufferStorageOES( GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, mBackingWidth, mBackingHeight );
// 	}
// 
// 	if( glCheckFramebufferStatusOES( GL_FRAMEBUFFER_OES ) != GL_FRAMEBUFFER_COMPLETE_OES ) {
// 		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
//----->
//PROPOSED:
#if ! defined ( CINDER_GLES2 )
  glBindFramebufferOES( GL_FRAMEBUFFER_OES, mViewFramebuffer );
  glBindRenderbufferOES( GL_RENDERBUFFER_OES, mViewRenderBuffer );
  [mContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)mCinderView.layer];
  glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &mBackingWidth );
  glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &mBackingHeight );

  if( mUsingMsaa ) {
    glBindFramebufferOES( GL_FRAMEBUFFER_OES, mMsaaFramebuffer );
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_DEPTH_COMPONENT16_OES, mBackingWidth, mBackingHeight );
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, mMsaaRenderBuffer );
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER_OES, mMsaaSamples, GL_RGB5_A1_OES, mBackingWidth, mBackingHeight );    
  }
  else {
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, mDepthRenderBuffer );
    glRenderbufferStorageOES( GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, mBackingWidth, mBackingHeight );
  }

  if( glCheckFramebufferStatusOES( GL_FRAMEBUFFER_OES ) != GL_FRAMEBUFFER_COMPLETE_OES ) {
    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
	}
#else
  glBindFramebuffer( GL_FRAMEBUFFER, mViewFramebuffer );
  glBindRenderbuffer( GL_RENDERBUFFER, mViewRenderBuffer );
  [mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)mCinderView.layer];
  glGetRenderbufferParameteriv( GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mBackingWidth );
  glGetRenderbufferParameteriv( GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mBackingHeight );

  if( mUsingMsaa ) {
    glBindFramebuffer( GL_FRAMEBUFFER, mMsaaFramebuffer );
    glBindRenderbuffer( GL_RENDERBUFFER, mDepthRenderBuffer );
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER, mMsaaSamples, GL_DEPTH_COMPONENT16, mBackingWidth, mBackingHeight );
    glBindRenderbuffer( GL_RENDERBUFFER, mMsaaRenderBuffer );
    glRenderbufferStorageMultisampleAPPLE( GL_RENDERBUFFER, mMsaaSamples, GL_RGB5_A1, mBackingWidth, mBackingHeight );    
  }
  else {
    glBindRenderbuffer( GL_RENDERBUFFER, mDepthRenderBuffer );
    glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, mBackingWidth, mBackingHeight );
  }

  if( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE ) {
    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	}
#endif

}

- (void)makeCurrentContext
{
//OLD:
//----->
// 	[EAGLContext setCurrentContext:context];
// 
// 	// This application only creates a single default framebuffer which is already bound at this point.
// 	// This call is redundant, but needed if dealing with multiple framebuffers.
// 	glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
// 	glViewport(0, 0, backingWidth, backingHeight);
//----->
//NEW:
//----->
// 	[EAGLContext setCurrentContext:mContext];
//     
// 	// This application only creates a single default framebuffer which is already bound at this point.
// 	// This call is redundant, but needed if dealing with multiple framebuffers.
// 	if( mUsingMsaa ) {
// 		glBindFramebufferOES( GL_FRAMEBUFFER_OES, mMsaaFramebuffer );
// 	}
// 	else {
// 		glBindFramebufferOES( GL_FRAMEBUFFER_OES, mViewFramebuffer );
// 	}
//     
// 	glViewport( 0, 0, mBackingWidth, mBackingHeight );
// 	
//----->
//PROPOSED:
  [EAGLContext setCurrentContext:mContext];
    
  // This application only creates a single default framebuffer which is already bound at this point.
  // This call is redundant, but needed if dealing with multiple framebuffers.
#if ! defined ( CINDER_GLES2 )
  if( mUsingMsaa ) {
    glBindFramebufferOES( GL_FRAMEBUFFER_OES, mMsaaFramebuffer );
  }
  else {
    glBindFramebufferOES( GL_FRAMEBUFFER_OES, mViewFramebuffer );
  }
#else
  if( mUsingMsaa ) {
    glBindFramebuffer( GL_FRAMEBUFFER, mMsaaFramebuffer );
  }
  else {
    glBindFramebuffer( GL_FRAMEBUFFER, mViewFramebuffer );
  }
#endif
    
  glViewport( 0, 0, mBackingWidth, mBackingHeight );

}

- (void)flushBuffer
{
//OLD:
//----->
// 	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
// 	[context presentRenderbuffer:GL_RENDERBUFFER];
//----->
//NEW:
//----->
// 	if( mUsingMsaa ) {
// 		GLenum attachments[] = { GL_DEPTH_ATTACHMENT_OES };
// 		glDiscardFramebufferEXT( GL_READ_FRAMEBUFFER_APPLE, 1, attachments ); 
// 		
// 		glBindFramebufferOES( GL_READ_FRAMEBUFFER_APPLE, mMsaaFramebuffer );
// 		glBindFramebufferOES( GL_DRAW_FRAMEBUFFER_APPLE, mViewFramebuffer );
// 		
// 		glResolveMultisampleFramebufferAPPLE();	
// 	}
// 
//     glBindRenderbufferOES( GL_RENDERBUFFER_OES, mViewRenderBuffer );
//     [mContext presentRenderbuffer:GL_RENDERBUFFER_OES];
//----->
//PROPOSED:
  if( mUsingMsaa ) {
#if ! defined ( CINDER_GLES2 )
    GLenum attachments[] = { GL_DEPTH_ATTACHMENT_OES };
    glDiscardFramebufferEXT( GL_READ_FRAMEBUFFER_APPLE, 1, attachments ); 
    
    glBindFramebufferOES( GL_READ_FRAMEBUFFER_APPLE, mMsaaFramebuffer );
    glBindFramebufferOES( GL_DRAW_FRAMEBUFFER_APPLE, mViewFramebuffer );
    
    glResolveMultisampleFramebufferAPPLE(); 
  }

    glBindRenderbufferOES( GL_RENDERBUFFER_OES, mViewRenderBuffer );
    [mContext presentRenderbuffer:GL_RENDERBUFFER_OES];
#else
    GLenum attachments[] = { GL_DEPTH_ATTACHMENT };
    glDiscardFramebufferEXT( GL_READ_FRAMEBUFFER_APPLE, 1, attachments ); 
    
    glBindFramebuffer( GL_READ_FRAMEBUFFER_APPLE, mMsaaFramebuffer );
    glBindFramebuffer( GL_DRAW_FRAMEBUFFER_APPLE, mViewFramebuffer );
    
    glResolveMultisampleFramebufferAPPLE(); 
  }

    glBindRenderbuffer( GL_RENDERBUFFER, mViewRenderBuffer );
    [mContext presentRenderbuffer:GL_RENDERBUFFER];
#endif
}

- (void)setFrameSize:(CGSize)newSize
{
	[self layoutSubviews];
}

- (void)defaultResize
{
//OLD:
//	cinder::gl::setMatricesWindow( backingWidth, backingHeight );
//NEW:
//----->
// 	glViewport( 0, 0, mBackingWidth, mBackingHeight );
// 	ci::gl::setMatricesWindowPersp( mCinderView.bounds.size.width, mCinderView.bounds.size.height );
//----->
//PROPOSED:
#if ! defined ( CINDER_GLES2 )
  glViewport( 0, 0, mBackingWidth, mBackingHeight );
  ci::gl::setMatricesWindowPersp( mCinderView.bounds.size.width, mCinderView.bounds.size.height );
#endif
}

- (BOOL)needsDrawRect
{
	return NO;
}

@end
