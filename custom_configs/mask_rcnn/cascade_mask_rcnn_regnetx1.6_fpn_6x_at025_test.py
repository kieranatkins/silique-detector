_base_ = [
    '../../configs/_base_/models/cascade-mask-rcnn_r50_fpn.py',
    '../datasets/at025_v2.py',
    '../../configs/_base_/schedules/schedule_2x.py',
    '../../configs/_base_/default_runtime.py'
]

NUM_CLASSES = 1

model = dict(
    data_preprocessor=dict(
        mean=[x * 255 for x in [0.986331, 0.98630885, 0.98370202]],
        std=[x * 255 for x in [0.05355581, 0.05335216, 0.06885611]],
    ),
    backbone=dict(
        _delete_=True,
        type='RegNet',
        arch='regnetx_1.6gf',
        out_indices=(0, 1, 2, 3),
        frozen_stages=-1,
        norm_cfg=dict(type='BN', requires_grad=True),
        norm_eval=True,
        style='pytorch'
    ),
    neck=dict(
        type='FPN',
        in_channels=[72, 168, 408, 912],
        out_channels=256,
        num_outs=5
    ),
    roi_head=dict(
        bbox_head=[
            dict(
                type='Shared2FCBBoxHead',
                in_channels=256,
                fc_out_channels=1024,
                roi_feat_size=7,
                num_classes=NUM_CLASSES,
                bbox_coder=dict(
                    type='DeltaXYWHBBoxCoder',
                    target_means=[0., 0., 0., 0.],
                    target_stds=[0.1, 0.1, 0.2, 0.2]),
                reg_class_agnostic=True,
                loss_cls=dict(
                    type='CrossEntropyLoss',
                    use_sigmoid=False,
                    loss_weight=1.0),
                loss_bbox=dict(type='SmoothL1Loss', beta=1.0,
                               loss_weight=1.0)),
            dict(
                type='Shared2FCBBoxHead',
                in_channels=256,
                fc_out_channels=1024,
                roi_feat_size=7,
                num_classes=NUM_CLASSES,
                bbox_coder=dict(
                    type='DeltaXYWHBBoxCoder',
                    target_means=[0., 0., 0., 0.],
                    target_stds=[0.05, 0.05, 0.1, 0.1]),
                reg_class_agnostic=True,
                loss_cls=dict(
                    type='CrossEntropyLoss',
                    use_sigmoid=False,
                    loss_weight=1.0),
                loss_bbox=dict(type='SmoothL1Loss', beta=1.0,
                               loss_weight=1.0)),
            dict(
                type='Shared2FCBBoxHead',
                in_channels=256,
                fc_out_channels=1024,
                roi_feat_size=7,
                num_classes=NUM_CLASSES,
                bbox_coder=dict(
                    type='DeltaXYWHBBoxCoder',
                    target_means=[0., 0., 0., 0.],
                    target_stds=[0.033, 0.033, 0.067, 0.067]),
                reg_class_agnostic=True,
                loss_cls=dict(
                    type='CrossEntropyLoss',
                    use_sigmoid=False,
                    loss_weight=1.0),
                loss_bbox=dict(type='SmoothL1Loss', beta=1.0, loss_weight=1.0))
        ],
        mask_head=dict(
            num_classes=NUM_CLASSES
        )
    ),
    test_cfg=dict(rcnn=dict(max_per_img=150)))

train_dataloader = dict(
    batch_size=1,
    num_workers=1
)

sched = 3

env_cfg=dict(cudnn_benchmark=True)

optim_wrapper = dict(
    type='OptimWrapper',
    optimizer=dict(
        type='SGD',
        lr=0.01,
        momentum=0.9,
        weight_decay=0.0001),
)
param_scheduler = [
    dict(type='LinearLR', start_factor=0.001, by_epoch=False, begin=0, end=100),
    dict(type='MultiStepLR', by_epoch=True, milestones=[n*sched for n in [8, 11]], gamma=0.1)
]

train_cfg = dict(type='EpochBasedTrainLoop', max_epochs=12*sched, val_interval=3)

default_hooks = dict(
    logger=dict(
        type='LoggerHook',
        interval=10
    ),
    checkpoint=dict(
        type='CheckpointHook',
        interval=12,
        max_keep_ckpts=3)
)

log_config = dict(interval=1, hooks=[dict(type='TextLoggerHook'), dict(type='TensorboardLoggerHook')])
workflow = [('train', 1)]
fp16 = dict(loss_scale=dict(init_scale=512))

test_dataloader=dict(
    dataset=dict(
        ann_file='at025_v2_fixed_test.json',
        data_root='test_data',
        data_prefix=dict(img='images/')
    ),
    batch_size=1,
    num_workers=1
)

test_evaluator=dict(
    ann_file='test_data/at025_v2_fixed_test.json',
)

