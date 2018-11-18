mutable struct CallbackContext
    model::Model
    context::Ptr{Cvoid}
end

function callback_wrapper(context::Ptr{Cvoid},
                          context_id::Clong,
                          user_handle::Ptr{Cvoid})
    (model, user_callback) = unsafe_pointer_to_objref(user_handle)::Tuple{Model, Function}
    # Run the `user_callback`.
    user_callback(CallbackContext(model, context), context_id)
    # Exit normally.
    return Cint(0)
end

"""
    cpx_callbacksetfunc(model::Model, context_mask::Clong, user_callback::Function)

Set the general callback function of model to `user_callback`.

`user_callback` is a function that takes two arguments. The first is a
`CallbackContext` instance, and the second is a `Clong` indicating where the
callback is being called from.

## Examples

    function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
        CPLEX.cpx_callbackabort(cb_context)
    end
    CPLEX.cpx_callbacksetfunc(model, Clong(0), my_callback)
"""
function cpx_callbacksetfunc(model::Model, context_mask::Clong, user_callback::Function)
    c_callback = @cfunction(
        callback_wrapper, Cint, (Ptr{Cvoid}, Clong, Ptr{Cvoid})
    )
    user_handle = (model, user_callback)::Tuple{Model, Function}
    ret = @cpx_ccall(callbacksetfunc,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Clong, Ptr{Cvoid}, Any),
        model.env, model.lp, context_mask, c_callback, user_handle
    )
    if ret != 0
        throw(CplexError(model.env, ret))
    end
    # We need to keep a reference to the callback function so that it isn't
    # garbage collected.
    model.callback = user_handle
    return
end

# int CPXXcallbackabort( CPXCALLBACKCONTEXptr context )
function cpx_callbackabort(callback_data::CallbackContext)
    return_status = @cpx_ccall(callbackabort,
        Cint,
        (Ptr{Cvoid},),
        callback_data.context
    )
    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end
    return
end

# # import Gallium
#
# @enum CbSolStrat CPXCALLBACKSOLUTION_CHECKFEAS CPXCALLBACKSOLUTION_PROPAGATE
#
# mutable struct GenCallbackData
#     # cbdata::Ptr{Cvoid}
#     ncol::Cint
#     obj::Any
# end
#
# function cbgetrelaxedpoint(env::Env,context_::Ptr{Cvoid},x::Vector{Cdouble},start::Cint,final::Cint,obj_::Ptr{Cvoid})
#     stat=@cpx_ccall(callbackgetrelaxationpoint,Cint,(
#     Ptr{Cvoid},
#     Ptr{Cdouble},
#     Cint,
#     Cint,
#     Ptr{Cdouble}
#     ),
#     context_,x,start,final,obj_)
#     # println("cbgetrelaxedpoint status $stat")#@
#     if stat!=0
#         throw(CplexError(env,stat))
#     end
#     return stat
# end
#
# function cbpostheursoln(env::Env,context_::Ptr{Cvoid},cnt::Cint,ind::Vector{Cint},val::Vector{Cdouble},obj::Cdouble,strat::CbSolStrat)
#     stat=@cpx_ccall(callbackpostheursoln,Cint,(
#     Ptr{Cvoid},
#     Cint,
#     # ConstPtr{Cint},
#     # ConstPtr{Cdouble},
#     Ptr{Cint},
#     Ptr{Cdouble},
#     # Ptr{Cvoid},
#     # Ptr{Cvoid},
#     Cdouble,
#     Cint
#     ),
#     context_,cnt,ind,val,obj,strat)
#
#     println("context is $context_")#@
#     println("cbpostheursoln status $stat")#@
#
#     if stat!=0
#         throw(CplexError(env,stat))
#     end
#     return stat
# end
#
# function rounddownheur(env::Env,context_::Ptr{Cvoid},userdata_::Ptr{Cvoid})
#     userdata=unsafe_pointer_to_objref(userdata_)
#     cols=userdata.ncol
#     obj=userdata.obj
#
#     x=Vector{Float64}(cols)
#     ind=Vector{Cint}(cols)
#     objrel=0.0
#
#     status=cbgetrelaxedpoint(env,context_,x,Cint(0),Cint(cols-1),pointer_from_objref(objrel))
#
#     # x=[-0.0, 1.0, -0.0, -0.0, 1.0, -0.0, -0.0, 1.0, 0.799815, -0.0, -0.0, -0.0, 1.0, 1.0, -0.0, 1.0, -0.0, 1.0, 1.0, -0.0, 1.0, -0.0, -0.0, -0.0, 1.0, -0.0, 0.691323, 0.450987, -0.0, 1.0, -0.0, -0.0, -0.0, -0.0, -0.0, 0.930968, 1.0, -0.0, 0.731431, -0.0, -0.0, -0.0, 0.544755, -0.0, 0.45098, 1.0, 1.0, -0.0, -0.0, -0.0, -0.0, -0.0, 1.0, -0.0, -0.0, 1.0, 0.293466, -0.0, 1.0, -0.0]
#     #
#     # objrel=-7839.278018021
#
#     if status!=0
#         error("Could not get solution $status")
#     end
#     println("before pointer of x is: ",pointer_from_objref(x))#@
#     for j in 1:cols
#         ind[j]=j
#
#         if x[j]>1.0e-6
#             frac=x[j]-floor(x[j])
#             frac=min(1-frac,frac)
#             if frac>1.0e-6
#                 objrel-=x[j]*obj[j]
#                 x[j]=0
#             end
#         end
#     end
#
#     println("later pointer of x is: ", pointer_from_objref(x))#@
#     println("pointer of ind is: ", pointer_from_objref(ind))#@
#     println("objrel is: $objrel")#@
#     println("context is $context_")#@
#     # println("x pointer: ", pointer_from_objref(x))#@
#
#     # @enter cbpostheursoln(env,context_,cols,ind,x,objrel,CPXCALLBACKSOLUTION_CHECKFEAS)
#
#     status=cbpostheursoln(env,context_,cols,ind,x,objrel,CPXCALLBACKSOLUTION_CHECKFEAS)
#
#     clear!(:x)
#     clear!(:ind)
#
#     # println("later pointer of x is: ", pointer_from_objref(x))#@
#     # println("pointer of ind is: ", pointer_from_objref(ind))#@
#     # println("objrel is: $objrel")
#
#     if status!=0
#         error("Could not post solution $status")
#     end
#
#     return status
# end
#
# function cplex_callback_wrapper(env::Env,context_::Ptr{Cvoid},where::Clong,userdata_::Ptr{Cvoid})
#     status=0
#
#     if (where==CPX_CALLBACKCONTEXT_RELAXATION)
#         status=rounddownheur(env,context_,userdata_)
#     else
#         println("ERROR: Callback called in an unexpected context.")
#         return convert(Cint,1)
#     end
#     return status
# end
#
# # type Cplex_Callback
# #
# # end
#
# function setcallbackfunc(env::Env,model::Model,where::Clong,userdata_::Ptr{Cvoid})
#     cplex_callback_c = @cfunction(
#         cplex_callback_wrapper,
#         Cint,
#         (Env, Ptr{Cvoid}, Clong, Ptr{Cvoid})
#     )
#
#     # println("cplex_callback_c wrapper: $cplex_callback_c")#@
#     # println("userdata_: $userdata_")
#
#     stat=@cpx_ccall(callbacksetfunc, Cint,(
#     Ptr{Cvoid},
#     Ptr{Cvoid},
#     Clong,
#     Ptr{Cvoid},
#     Ptr{Cvoid}
#     ),
#     env.ptr,model.lp,where,cplex_callback_c,userdata_)
#     if stat != 0
#         throw(CplexError(env, stat))
#     end
#
#     model.callback=userdata_ #prevent gabage collect of userdata_
#
#     return stat
# end
