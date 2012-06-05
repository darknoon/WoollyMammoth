
#import "DNTriangleTriangleClip.h"

static inline float dot(CGPoint a, CGPoint b) {
	return a.x*b.x + a.y*b.y;
}

/*
void drawDot(CGContextRef context, CGPoint inPoint, float radius) {
	CGContextFillEllipseInRect(context, (CGRect) {
		.origin.x = inPoint.x - radius,
		.origin.y = inPoint.y - radius,
		.size.height = radius * 2.f,
		.size.width = radius * 2.f,
	});
}

void drawKaleidoscopePoint(CGContextRef context, KaleidoscopeGeometryPoint inPoint, float radius) {
	[[UIColor colorWithRed:inPoint.tc[0] green:inPoint.tc[1] blue:0.0f alpha:1.0f] set];
	CGContextFillEllipseInRect(context, (CGRect) {
		.origin.x = inPoint.v[0] - radius,
		.origin.y = inPoint.v[1] - radius,
		.size.height = radius * 2.f,
		.size.width = radius * 2.f,
	});
	
}


void drawTriInContext(const CGPoint *tri, CGContextRef context, BOOL stroke) {
	//Draw triangle to clip to
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, tri[0].x, tri[0].y);
	CGContextAddLineToPoint(context, tri[1].x, tri[1].y);
	CGContextAddLineToPoint(context, tri[2].x, tri[2].y);
	CGContextClosePath(context);
	
	stroke ? CGContextStrokePath(context) : CGContextFillPath(context) ;
}

void drawKaleidoscopeTriInContext(const KaleidoscopeGeometryPoint *tri, CGContextRef context, BOOL stroke) {	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, tri[0].v[0], tri[0].v[1]);
	CGContextAddLineToPoint(context, tri[1].v[0], tri[1].v[1]);
	CGContextAddLineToPoint(context, tri[2].v[0], tri[2].v[1]);
	CGContextClosePath(context);
	
	stroke ? CGContextStrokePath(context) : CGContextFillPath(context) ;
}
 */

KaleidoscopeGeometryPoint pointWithBasis(int uc, int vc, CGPoint origin, CGPoint offset, CGPoint basisU, CGPoint basisV, float maxS, float maxT) {
	return (KaleidoscopeGeometryPoint) {
		.v = { origin.x + (uc + offset.x)*basisU.x + (vc + offset.y)*basisV.x,
			origin.y + (uc + offset.x)*basisU.y + (vc + offset.y)*basisV.y },
		.tc = { uc&1 ? 0.1f : 0.9,
			vc&1 ? 0.0f : maxT }
	};
}

//http://www.blackpawn.com/texts/pointinpoly/default.html
static inline BOOL pointInTriangle(KaleidoscopeGeometryPoint p, CGPoint a, CGPoint b, CGPoint c) {
	// Compute vectors        
	CGPoint v0,v1,v2;
	v0.x = b.x - a.x;
	v0.y = b.y - a.y;
	
	v1.x = c.x - a.x;
	v1.y = c.y - a.y;
	
	v2.x = p.v[0] - a.x;
	v2.y = p.v[1] - a.y;
	
	// Compute dot products
	float dot00 = dot(v0, v0);
	float dot01 = dot(v0, v1);
	float dot02 = dot(v0, v2);
	float dot11 = dot(v1, v1);
	float dot12 = dot(v1, v2);
	
	// Compute barycentric coordinates
	float invDenom = 1.0f / (dot00 * dot11 - dot01 * dot01);
	float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
	float v = (dot00 * dot12 - dot01 * dot02) * invDenom;
	
	// Check if point is in triangle
	return (u > 0) && (v > 0) && (u + v < 1);
}

float ratioAlongLineSegment(CGPoint a0, CGPoint a1, CGPoint b0, CGPoint b1) {
	float ua = (b1.x - b0.x) * (a0.y - b0.y) - (b1.y - b0.y) * (a0.x - b0.x);
	//float ub = (a1.x - a0.x) * (a0.y - b0.y) - (a1.y - a0.y) * (a0.x - b0.x);
	float denominator = (b1.y - b0.y) * (a1.x - a0.x) - (b1.x - b0.x) * (a1.y - a0.y);
	
	return ua / denominator;
}

/*
void drawTextLabelAtPoint(NSString *text, CGPoint inPoint) {
	[text drawAtPoint:inPoint withFont:[UIFont boldSystemFontOfSize:10]];
}*/

//Will increment outTrisUsed, must have room for at least two triangles
void clipTriangleAgainstLine(KaleidoscopeGeometryPoint *inTri, CGPoint lineA, CGPoint lineB, KaleidoscopeGeometryPoint *outTris, int *outTrisUsed) {
	//NSLog(@"\nclip triangle against line");
	
	//Change basis into 
	//AB = lineB - lineA <= vector along clipping line
	//N perpendicular
	const CGPoint AB = {lineB.x - lineA.x, lineB.y - lineA.y};
	const CGPoint N = {AB.y, -AB.x};
	
	int vertsUsed = 0;
	
	for (int i=0, inext = 1; i < 3; i++, inext=(i+1)%3) {
		const CGPoint AP = {inTri[i].v[0] - lineA.x, inTri[i].v[1] - lineA.y};
		//If the first point of the line segment is in, emit it
		if (dot(AP,N) > -0.0001) {
			//output the vertex
			if (vertsUsed == 3) {
				//Output another copy of the previous vertex if we're starting a second triangle
				outTris[*outTrisUsed*3 + 3] = outTris[*outTrisUsed*3 + 2];
				vertsUsed++;
				//NSLog(@"Doubling vertex %@", NSStringFromCGPoint(outTris[*outTrisUsed*3 + 2]));
			}
			outTris[*outTrisUsed*3 + vertsUsed] = inTri[i];
			vertsUsed++;
			//NSLog(@"Output inside vertex: %@", NSStringFromCGPoint(inTri[i]));
		}
		
		float u = ratioAlongLineSegment((CGPoint){inTri[i].v[0], inTri[i].v[1]},
										(CGPoint){inTri[inext].v[0], inTri[inext].v[1]},
										lineA,
										lineB);
		
		//If the line intersects this line segment
		if (u > 0 && u < 1) {
			//output the vertex
			if (vertsUsed == 3) {
				//Output another copy of the previous vertex if we're starting a second triangle
				outTris[*outTrisUsed*3 + 3] = outTris[*outTrisUsed*3 + 2];
				//NSLog(@"Doubling vertex %@", NSStringFromCGPoint(outTris[*outTrisUsed*3 + 2]));
				vertsUsed++;
			}
			outTris[*outTrisUsed*3 + vertsUsed].v[0] = (1-u) * inTri[i].v[0] + u * inTri[inext].v[0];
			outTris[*outTrisUsed*3 + vertsUsed].v[1] = (1-u) * inTri[i].v[1] + u * inTri[inext].v[1];
			
			outTris[*outTrisUsed*3 + vertsUsed].tc[0] = (1-u) * inTri[i].tc[0] + u * inTri[inext].tc[0];
			outTris[*outTrisUsed*3 + vertsUsed].tc[1] = (1-u) * inTri[i].tc[1] + u * inTri[inext].tc[1];
			//NSLog(@"Output intersection vertex: %@", NSStringFromCGPoint(outTris[*outTrisUsed*3 + vertsUsed]));
			vertsUsed++;
		}
	}
	//Emit the first point again if we should have 2 triangles
	if (vertsUsed == 5) {
		outTris[*outTrisUsed*3 + 5] = outTris[*outTrisUsed*3 + 0];
		vertsUsed++;
		//NSLog(@"Doubled first point: %@", NSStringFromCGPoint(outTris[*outTrisUsed*3 + 5]));
	}
	if ( !(vertsUsed == 0 || vertsUsed == 3 || vertsUsed == 6)) {
		//NSLog(@"Assert failed! Verts: %d", vertsUsed);
	};
	*outTrisUsed += vertsUsed / 3;
}


void clipTriangleAgainstTriangle(KaleidoscopeGeometryPoint *inTri, CGPoint *againstTri, KaleidoscopeGeometryPoint *outTris, int *outTrisUsed) {
	const BOOL inside[3] = {
		pointInTriangle(inTri[0], againstTri[0], againstTri[1], againstTri[2]),
		pointInTriangle(inTri[1], againstTri[0], againstTri[1], againstTri[2]),
		pointInTriangle(inTri[2], againstTri[0], againstTri[1], againstTri[2]),
	};
	
	//TODO: add indexing
	int trisUsed = 0;
	int outTriIndex = 0; //Defined as 3 * trisUsed for now
	
	if (inside[0] && inside[1] && inside[2]) {
		//All inside: just emit the input triangle
		for (int i=0; i<3; i++) {
			outTris[outTriIndex++] = inTri[i];
		}
		trisUsed++;
	} else {
		//Might be in or out, we don't know...		
		
		//Each input tri can generate up to 8 output triangles
		//make 2 temp buffers
		KaleidoscopeGeometryPoint tempTrisBufStorage[2][4*3];
		int tempTrisBufStorageCount[2] = {0,0};
		
		//Clip the initial triangle into tempTrisBufStorage[0]
		clipTriangleAgainstLine(inTri, againstTri[0], againstTri[1], tempTrisBufStorage[0], &tempTrisBufStorageCount[0]);
		//NSLog(@"%d triangles after first clip", tempTrisBufStorageCount[0]);
		
		//Clip thi tempTrisBufStorageCount[0] clipped triangles into tempTrisBufStorage[1]
		for (int i=0; i<tempTrisBufStorageCount[0]; i++) {
			clipTriangleAgainstLine(&tempTrisBufStorage[0][3 * i], againstTri[1], againstTri[2], tempTrisBufStorage[1], &tempTrisBufStorageCount[1]);
		}
		//NSLog(@"%d triangles after middle clip", tempTrisBufStorageCount[1]);
		
		//Output the resulting triangles
		for (int i=0; i<tempTrisBufStorageCount[1]; i++) {
			clipTriangleAgainstLine(&tempTrisBufStorage[1][3 * i], againstTri[2], againstTri[0], outTris, &trisUsed);
		}		
		//NSLog(@"%d triangles after last clip", trisUsed);
	}
	
	*outTrisUsed = trisUsed;
}

void reflectVertices8(KaleidoscopeGeometryPoint *inPoints, size_t inPointsCount, float inAspectRatio, KaleidoscopeGeometryPoint *outPoints, NSUInteger *outPointsCount) {
	int pointsCount = 0;
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] = inPoints[i].v[0];
		outPoints[pointsCount].v[1] = inAspectRatio * inPoints[i].v[1];
		pointsCount++;
	}
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] = inPoints[i].v[1];
		outPoints[pointsCount].v[1] = inAspectRatio * inPoints[i].v[0];
		pointsCount++;
	}
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] = -inPoints[i].v[0];
		outPoints[pointsCount].v[1] =  inAspectRatio * inPoints[i].v[1];
		pointsCount++;
	}
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] = -inPoints[i].v[1];
		outPoints[pointsCount].v[1] =  inAspectRatio * inPoints[i].v[0];
		pointsCount++;
	}
	////
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] =  inPoints[i].v[0];
		outPoints[pointsCount].v[1] = inAspectRatio * -inPoints[i].v[1];
		pointsCount++;
	}
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] =  inPoints[i].v[1];
		outPoints[pointsCount].v[1] = inAspectRatio * -inPoints[i].v[0];
		pointsCount++;
	}
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] = -inPoints[i].v[0];
		outPoints[pointsCount].v[1] = inAspectRatio * -inPoints[i].v[1];
		pointsCount++;
	}
	for (int i=0; i<inPointsCount; i++) {
		outPoints[pointsCount] = inPoints[i];
		outPoints[pointsCount].v[0] = -inPoints[i].v[1];
		outPoints[pointsCount].v[1] = inAspectRatio * -inPoints[i].v[0];
		pointsCount++;
	}
	*outPointsCount = pointsCount;
}


