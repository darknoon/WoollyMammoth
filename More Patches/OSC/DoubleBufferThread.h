/*
 *  DoubleBufferThread.h
 *  PearlTr3Sky20
 *
 *  Created by Warren Stringer on 6/12/10.
 *  Copyright 2010 Muse.com, Inc. All rights reserved.
 *
 */

#ifndef DoubleBufferThread_H
#define DoubleBufferThread_H

#include <deque>
#include <pthread.h>
#include <iostream>
#include <assert.h>

template <typename T> struct DoubleBufferThread {
    
    std::deque<T*> _messages[2]; // double buffered with messageIn == mesageOut^1;
    
    int _messageIn;
    int _messageOut;
	pthread_t _thread;
	pthread_mutex_t _mutex;
    
    DoubleBufferThread() {
        
        pthread_mutex_init(&_mutex, NULL);
        _messageIn  = 0;
        _messageOut = 1;
    }

    void flipMessageDoubleBuffer() {
        
        pthread_mutex_lock(&_mutex);
        _messageIn  ^= 1;
        _messageOut ^= 1;
        pthread_mutex_unlock(&_mutex);
    }
    void push(T*t) {
     
        _messages[_messageIn].push_back(t);
    }
    T* pop() {
        if (_messages[_messageOut].size() ==0)
            return NULL;
        T* t = _messages[_messageOut].front();
        _messages[_messageOut].pop_front();
        return (t);
    }
        
    void clearBuffers() {
    
        pthread_mutex_lock(&_mutex);
        
        while (_messages[_messageIn].size() > 0) {
            
            T* msg = _messages[_messageIn].front();
            delete msg;
            _messages[_messageIn].pop_front();
        }
        while (_messages[_messageOut].size() > 0) {
            
            T* msg = _messages[_messageOut].front();
            delete msg;
            _messages[_messageOut].pop_front();
        }
        pthread_mutex_unlock(&_mutex);
    }
};

#endif